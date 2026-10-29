import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/storage/account_store.dart';
import '../../../core/storage/server_store.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/server_url_validator.dart';
import '../../../shared/widgets/voce_avatar.dart';
import '../../../shared/widgets/voce_dialog.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/server_connection.dart';
import '../domain/invite_link.dart';

class ServerPickerScreen extends ConsumerStatefulWidget {
  const ServerPickerScreen({super.key, this.openAdd = false});

  final bool openAdd;

  @override
  ConsumerState<ServerPickerScreen> createState() => _ServerPickerScreenState();
}

class _ServerPickerScreenState extends ConsumerState<ServerPickerScreen> {
  String? _selectedId;
  bool _switching = false;
  String? _removingId;
  bool get _busy => _switching || _removingId != null;
  String? _connectError;
  CancelToken? _selection;

  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddSheet();
      });
    }
  }

  @override
  void dispose() {
    _selection?.cancel('Picker closed');
    super.dispose();
  }

  Future<void> _prepareLogin(ServerConfig config, CancelToken token) async {
    final connection = ref.read(serverConnectionProvider);
    final organization =
        await connection.probe(config.baseUrl, cancelToken: token);
    void ensureActive() {
      if (!mounted || token.isCancelled) {
        throw const ServerConnectionException(
            ServerConnectionFailure.cancelled);
      }
    }

    ensureActive();
    final store = ref.read(serverStoreProvider.notifier);
    // Failed probes never save/select a server or touch the current account.
    // Repeated attempts at the same address reuse the existing entry.
    final existing = store.list
        .where((s) =>
            ServerConnection.normalize(s.baseUrl) ==
            ServerConnection.normalize(config.baseUrl))
        .firstOrNull;
    final target = existing ?? config;
    if (existing == null) {
      await store.addServer(target).timeout(const Duration(seconds: 5));
      ensureActive();
    }
    final remoteName = organization['name'];
    if (remoteName is String) {
      await store
          .updateServerName(target.id, target.baseUrl, remoteName)
          .timeout(const Duration(seconds: 5));
      ensureActive();
    }
    await ref
        .read(accountStoreProvider.notifier)
        .clearCurrentAccount()
        .timeout(const Duration(seconds: 5));
    ensureActive();
    await store.selectServer(target.id).timeout(const Duration(seconds: 5));
    ensureActive();
    connection.prepareLogin(target.baseUrl, organization);
    ref.invalidate(authControllerProvider);
    await ref
        .read(authControllerProvider.future)
        .timeout(const Duration(seconds: 10));
    ensureActive();
  }

  Future<void> _continueWithSelected(
      List<ServerConfig> servers, String? currentServerId) async {
    if (_busy) return;
    final id = _selectedId ??
        (servers.any((s) => s.id == currentServerId)
            ? currentServerId
            : (servers.isNotEmpty ? servers.first.id : null));
    if (id == null) return;
    final config = servers.firstWhere((s) => s.id == id);
    final token = CancelToken();
    _selection = token;
    setState(() {
      _switching = true;
      _connectError = null;
    });
    try {
      await _prepareLogin(config, token);
      if (mounted && !token.isCancelled) context.go('/login');
    } catch (error) {
      if (mounted && !_isCancelled(error)) {
        setState(
            () => _connectError = _connectionError(AppL10n.of(context), error));
      }
    } finally {
      token.cancel('Selection finished');
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _removeServer(ServerConfig server) async {
    if (_busy) return;
    final l = AppL10n.of(context);
    final confirmed = await showVoceConfirm(
      context: context,
      title: l.serverRemoveTitle,
      body:
          '${safeText(server.name)}\n${safeText(server.baseUrl)}\n\n${l.serverRemoveBody}',
      confirmLabel: l.serverRemoveAction,
      cancelLabel: l.actionCancel,
      danger: true,
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _removingId = server.id;
      _connectError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).forgetServer(server.id);
      if (mounted)
        setState(() {
          if (_selectedId == server.id) _selectedId = null;
        });
    } catch (_) {
      if (mounted) setState(() => _connectError = l.serverRemoveFailed);
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  Future<void> _showAddSheet() async {
    final saved = await showModalBottomSheet<ServerConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddServerSheet(onSaved: _prepareLogin),
    );
    // Close the sheet before changing the page. A route change while its
    // callback was still pending could strand its loading/error widgets.
    if (saved != null && mounted) context.go('/login');
  }

  Future<void> _showInviteLinkSheet() async {
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _InviteLinkSheet(onResolved: (url, magicToken, cancelToken) async {
        final config = ServerConfig(
          id: '${Uri.parse(url).host.replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          baseUrl: url,
          name: Uri.parse(url).host,
        );
        await _prepareLogin(config, cancelToken);
      }),
    );
    if (token != null && mounted) context.go('/register', extra: token);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    final serverState = ref.watch(serverStoreProvider);

    return serverState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          body: Center(child: Text(safeText(l.errorPrefix(e.toString()))))),
      data: (state) {
        final servers = state.servers;
        final selectedIndex = _selectedId != null
            ? servers.indexWhere((s) => s.id == _selectedId)
            : servers.indexWhere((s) => s.id == state.currentServerId);
        final effectiveIndex = selectedIndex == -1 ? 0 : selectedIndex;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: .9,
                colors: [
                  Color(0xFF0071EC),
                  Color(0xFFA2C9F3),
                  Color(0xFFE9EBED)
                ],
                stops: [0, .6, 1],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.sizeOf(context).height < 500 ? 8 : 48,
                        20,
                        MediaQuery.sizeOf(context).height < 500 ? 8 : 32),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.serverPickerTitle,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0x990564F2))),
                          const Text('VoceChat.',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0564F2))),
                        ]),
                  ),
                  Expanded(
                      child: servers.isEmpty
                          ? SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(l.serverPickerEmptySubtitle,
                                        style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 24),
                                    PrimaryButton(
                                        label: l.serverPickerAddFirst,
                                        onPressed:
                                            _busy ? null : _showAddSheet),
                                  ]),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: servers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final server = servers[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  tileColor: Colors.white.withValues(alpha: .7),
                                  leading:
                                      VoceAvatar(name: server.name, size: 40),
                                  title: Text(safeText(server.name),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(safeText(server.baseUrl),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<int>(
                                          value: i,
                                          groupValue: effectiveIndex,
                                          onChanged: _busy
                                              ? null
                                              : (_) => setState(() {
                                                    _selectedId = server.id;
                                                    _connectError = null;
                                                  }),
                                        ),
                                        IconButton(
                                          key: ValueKey(
                                              'remove-server-${server.id}'),
                                          tooltip: l.serverRemoveTitle,
                                          onPressed: _busy
                                              ? null
                                              : () => _removeServer(server),
                                          icon: _removingId == server.id
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : Icon(Icons.delete_outline,
                                                  size: 22,
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant),
                                        ),
                                      ]),
                                  onTap: _busy
                                      ? null
                                      : () => setState(() {
                                            _selectedId = server.id;
                                            _connectError = null;
                                          }),
                                );
                              },
                            )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (servers.isNotEmpty) ...[
                        if (_switching)
                          _ConnectionFeedback(text: l.serverConnecting),
                        if (_connectError != null)
                          _ConnectionFeedback(
                              text: _connectError!, isError: true),
                        PrimaryButton(
                            label: l.serverPickerContinue,
                            isLoading: _switching,
                            onPressed: _busy
                                ? null
                                : () => _continueWithSelected(
                                    servers, state.currentServerId)),
                        TextButton.icon(
                            onPressed: _busy ? null : _showAddSheet,
                            icon: const Icon(Icons.add),
                            label: Text(l.serverPickerAdd)),
                      ],
                      TextButton.icon(
                          onPressed: _busy ? null : _showInviteLinkSheet,
                          icon: const Icon(Icons.link, size: 18),
                          label: Text(l.serverPickerUseInviteLink)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddServerSheet extends ConsumerStatefulWidget {
  final Future<void> Function(ServerConfig, CancelToken) onSaved;
  const _AddServerSheet({required this.onSaved});

  @override
  ConsumerState<_AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends ConsumerState<_AddServerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController(text: 'https://');
  bool _testing = false;
  bool _tested = false;
  bool _saving = false;
  String? _error;
  CancelToken? _request;

  @override
  void dispose() {
    _request?.cancel('Add sheet closed');
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_testing || _saving || !(_formKey.currentState?.validate() ?? false))
      return;
    final token = CancelToken();
    _request = token;
    setState(() {
      _testing = true;
      _tested = false;
      _error = null;
    });
    try {
      await ref
          .read(serverConnectionProvider)
          .probe(_urlCtrl.text, cancelToken: token);
      if (mounted && !token.isCancelled) setState(() => _tested = true);
    } catch (error) {
      if (mounted && !_isCancelled(error)) {
        setState(() => _error = _connectionError(AppL10n.of(context), error));
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (_testing || _saving || !(_formKey.currentState?.validate() ?? false))
      return;
    final url = ServerConnection.normalize(_urlCtrl.text);
    final config = ServerConfig(
      id: '${Uri.parse(url).host.replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      baseUrl: url,
      name: Uri.parse(url).host,
    );
    final token = CancelToken();
    _request = token;
    setState(() {
      _saving = true;
      _error = null;
      _tested = false;
    });
    try {
      await widget.onSaved(config, token);
      if (mounted && !token.isCancelled) Navigator.of(context).pop(config);
    } catch (error) {
      if (mounted && !_isCancelled(error)) {
        setState(() => _error = _connectionError(AppL10n.of(context), error));
      }
    } finally {
      token.cancel('Save finished');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l.serverAddTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _urlCtrl,
              enabled: !_testing && !_saving,
              onChanged: (_) => setState(() {
                _tested = false;
                _error = null;
              }),
              decoration: InputDecoration(
                labelText: l.serverUrl,
                hintText: l.serverUrlHint,
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
              validator: (v) => validateServerUrl(v, l),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _testing || _saving ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_tested ? Icons.check_circle_outline : Icons.wifi),
              label: Text(safeText(
                  _testing ? l.serverTesting : l.serverTestConnection)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            if (_tested) _ConnectionFeedback(text: l.serverTestSuccess),
            if (_saving) _ConnectionFeedback(text: l.serverConnecting),
            if (_error != null)
              _ConnectionFeedback(text: _error!, isError: true),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l.serverSave,
              isLoading: _saving,
              onPressed: _saving || _testing ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteLinkSheet extends ConsumerStatefulWidget {
  final Future<void> Function(
          String serverBaseUrl, String magicToken, CancelToken cancelToken)
      onResolved;
  const _InviteLinkSheet({required this.onResolved});

  @override
  ConsumerState<_InviteLinkSheet> createState() => _InviteLinkSheetState();
}

class _InviteLinkSheetState extends ConsumerState<_InviteLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _linkCtrl = TextEditingController();
  bool _checking = false;
  String? _error;
  CancelToken? _request;

  @override
  void dispose() {
    _request?.cancel('Invite sheet closed');
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _linkCtrl.text = text);
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    if (_checking || !(_formKey.currentState?.validate() ?? false)) return;
    final parsed = parseInviteLink(_linkCtrl.text);
    if (parsed is! InviteLinkParseValid) {
      setState(() => _error = l.inviteLinkInvalid);
      return;
    }
    final token = CancelToken();
    _request = token;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final valid = await ref.read(serverConnectionProvider).checkMagicToken(
          parsed.serverBaseUrl, parsed.magicToken,
          cancelToken: token);
      if (!valid) {
        if (mounted) setState(() => _error = l.inviteLinkExpired);
        return;
      }
      if (!mounted || token.isCancelled) return;
      await widget.onResolved(parsed.serverBaseUrl, parsed.magicToken, token);
      if (mounted && !token.isCancelled)
        Navigator.of(context).pop(parsed.magicToken);
    } catch (error) {
      if (mounted && !_isCancelled(error)) {
        setState(() => _error = _connectionError(l, error));
      }
    } finally {
      token.cancel('Invite finished');
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l.inviteLinkSheetTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _linkCtrl,
              enabled: !_checking,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l.inviteLinkHint,
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.inviteLinkRequired : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _checking ? null : _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, size: 18),
              label: Text(l.inviteLinkPasteFromClipboard),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              _ConnectionFeedback(text: _error!, isError: true),
            PrimaryButton(
              label: l.inviteLinkContinue,
              isLoading: _checking,
              onPressed: _checking ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

bool _isCancelled(Object error) =>
    error is ServerConnectionException &&
    error.failure == ServerConnectionFailure.cancelled;

String _connectionError(AppL10n l, Object error) {
  if (error is TimeoutException) return l.serverPreparingTimeout;
  if (error is ServerConnectionException) {
    return switch (error.failure) {
      ServerConnectionFailure.timeout => l.serverConnectionTimeout,
      ServerConnectionFailure.certificate => l.serverCertificateError,
      ServerConnectionFailure.invalidResponse => l.serverInvalidResponse,
      ServerConnectionFailure.http => l.serverHttpError(error.status ?? 0),
      _ => l.serverConnectionFailed,
    };
  }
  return l.serverSettingsFailed;
}

class _ConnectionFeedback extends StatelessWidget {
  const _ConnectionFeedback({required this.text, this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Semantics(
            liveRegion: true,
            child: Text(text,
                style: TextStyle(
                    color: isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant))),
      );
}
