import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../../../core/storage/account_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../legacy_ui/legacy_chrome.dart';
import '../../messages/presentation/file_display_utils.dart';
import '../data/lan_transfer.dart';
import '../data/outgoing_transfer_queue.dart';
import '../data/local_transfer_platform.dart';
import '../../sharing/application/incoming_share_provider.dart';

class LocalTransferScreen extends ConsumerStatefulWidget {
  const LocalTransferScreen({
    super.key,
    this.initialFiles = const [],
    this.incomingShare,
  });
  final List<String> initialFiles;
  final IncomingTransferSelection? incomingShare;
  @override
  ConsumerState<LocalTransferScreen> createState() =>
      _LocalTransferScreenState();
}

class _LocalTransferScreenState extends ConsumerState<LocalTransferScreen>
    with WidgetsBindingObserver {
  LanTransferEngine? _engine;
  LocalTransferIdentity? _identity;
  String? _error;
  bool _loading = true, _picking = false, _leaving = false;
  bool? _discoveryWanted;
  final _queue = OutgoingTransferQueue();
  List<File> get _selected => _queue.files;
  int _startGeneration = 0;
  IncomingShares? _shares;
  bool _shareReleased = false;
  String? _savingFile;
  String? _scope;
  ReceiveLocations _locations = const ReceiveLocations(null, null, []);
  bool _storageWarning = false;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialFiles.take(16).map(File.new));
    final share = widget.incomingShare;
    if (share != null) {
      _shares = ref.read(incomingSharesProvider.notifier);
      _selected.addAll(share.payload.files.map((f) => File(f.path)));
    }
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    final generation = ++_startGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    LanTransferEngine? engine;
    try {
      final account =
          ref.read(accountStoreProvider).valueOrNull?.currentAccountId;
      final identity = await prepareLocalTransfer();
      final root = await getApplicationDocumentsDirectory();
      final scope =
          sha256.convert(utf8.encode(account ?? 'local-device')).toString();
      final locations = await receiveLocations(scope);
      if (!mounted || generation != _startGeneration) return;
      await localTransferChannel.invokeMethod('discovery', {'enabled': true});
      engine = LanTransferEngine(
        context: identity.context,
        fingerprint: identity.fingerprint,
        name: identity.name,
        directory: Directory('${root.path}/local_transfers/$scope'),
        broadcasts: identity.broadcasts,
        onReceived: (item) => _storeIncoming(item, scope),
        onActive: (active, progress) => localTransferChannel.invokeMethod(
          'active',
          {'enabled': active, 'progress': progress},
        ),
      );
      await engine.start();
      engine.received.addAll(locations.received);
      if (!mounted || generation != _startGeneration) {
        engine.dispose();
        return;
      }
      _engine?.removeListener(_changed);
      _engine?.dispose();
      _identity = identity;
      _scope = scope;
      _locations = locations;
      _engine = engine;
      engine.addListener(_changed);
      localTransferChannel.setMethodCallHandler((call) async {
        if (call.method == 'stopped') await _engine?.cancel();
      });
      _setDiscoveryVisibility();
    } catch (_) {
      engine?.dispose();
      if (mounted && generation == _startGeneration) _error = 'network';
    } finally {
      if (mounted && generation == _startGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setDiscoveryVisibility();
  }

  void _setDiscoveryVisibility() {
    final visible = mounted &&
        TickerMode.of(context) &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _engine?.setDiscoveryEnabled(visible);
    if (_engine != null && _discoveryWanted != visible) {
      _discoveryWanted = visible;
      unawaited(
        localTransferChannel.invokeMethod(
            'discovery', {'enabled': visible}).catchError((Object _) {}),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _setDiscoveryVisibility();
  @override
  void dispose() {
    ++_startGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _engine?.removeListener(_changed);
    _engine?.dispose();
    _releaseShare();
    localTransferChannel.setMethodCallHandler(null);
    unawaited(
      localTransferChannel.invokeMethod(
          'discovery', {'enabled': false}).catchError((Object _) {}),
    );
    super.dispose();
  }

  void _releaseShare() {
    final id = widget.incomingShare?.payload.id;
    if (id != null && !_shareReleased) {
      _shareReleased = true;
      unawaited(
        Future<void>.microtask(() async {
          await _shares?.ack(id);
        }),
      );
    }
  }

  Future<void> _send(LanPeer peer) async {
    final engine = _engine;
    if (engine == null || engine.busy || _selected.isEmpty) return;
    await _queue.send(engine, peer);
    if (!mounted || _engine != engine) return;
    setState(() {});
    if (_selected.isEmpty) _releaseShare();
  }

  Future<void> _pick() async {
    if (_picking || _engine?.busy == true) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (result == null || !mounted) return;
      if (result.files.length > 16 || result.files.any((f) => f.path == null)) {
        throw const FormatException();
      }
      setState(() {
        _selected.clear();
        _selected.addAll(result.paths.whereType<String>().map(File.new));
      });
    } catch (_) {
      if (mounted) _message(AppL10n.of(context).localTransferFileError);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _saveReceived(LanReceivedFile item) async {
    if (_savingFile != null) return;
    final engine = _engine;
    setState(() => _savingFile = item.uri ?? item.file.path);
    try {
      final moved = await saveReceivedFileAs(item, _scope!);
      if (!mounted || _engine != engine) return;
      if (moved) {
        setState(() => engine?.received.remove(item));
        _message(AppL10n.of(context).localTransferSavedAs);
      }
    } catch (_) {
      if (mounted) _message(AppL10n.of(context).downloadFailed);
    } finally {
      if (mounted) setState(() => _savingFile = null);
    }
  }

  Future<LanReceivedFile> _storeIncoming(
      LanReceivedFile item, String scope) async {
    try {
      return await storeReceivedFile(item, scope);
    } catch (_) {
      if (mounted && _scope == scope) setState(() => _storageWarning = true);
      return item;
    }
  }

  Future<void> _copyConnection() async {
    final identity = _identity, engine = _engine;
    if (identity == null || identity.addresses.isEmpty || engine == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(
      text: engine.selfAt(identity.addresses.first).link.toString(),
    ));
    if (mounted) _message(AppL10n.of(context).localTransferCopied);
  }

  Future<void> _storageSettings() async {
    final scope = _scope;
    if (scope == null) return;
    final l = AppL10n.of(context);
    var busy = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (ctx, update) {
        Future<void> change(String kind, bool reset) async {
          update(() => busy = true);
          try {
            final value =
                await chooseReceiveLocation(scope, kind, reset: reset);
            if (!mounted || _scope != scope || value == null) return;
            setState(() {
              _locations = value;
              _engine?.received.removeWhere((item) => item.uri != null);
              _engine?.received.addAll(value.received);
              _storageWarning = false;
            });
          } catch (_) {
            if (mounted) _message(l.localTransferStorageError);
          } finally {
            if (ctx.mounted) update(() => busy = false);
          }
        }

        Widget folder(
                String kind, String title, String? location, IconData icon) =>
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(location ?? l.localTransferPrivateStorage),
              onTap: busy ? null : () => change(kind, false),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (location != null)
                  IconButton(
                    tooltip: l.localTransferResetFolder,
                    onPressed: busy ? null : () => change(kind, true),
                    icon: const Icon(Icons.restore),
                  ),
                IconButton(
                  tooltip: l.localTransferChooseFolder,
                  onPressed: busy ? null : () => change(kind, false),
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ]),
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(l.localTransferStorageSettings,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600))),
                  IconButton(
                      onPressed: busy ? null : () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                Text(l.localTransferNearbyShort,
                    style: TextStyle(color: AppTokens.gray500)),
                Text(l.localTransferStorageHint,
                    style: TextStyle(color: AppTokens.gray500)),
                folder('images', l.localTransferImageFolder, _locations.images,
                    Icons.image_outlined),
                folder('files', l.localTransferFileFolder, _locations.files,
                    Icons.insert_drive_file_outlined),
                if (busy) const LinearProgressIndicator(),
              ]),
        );
      }),
    );
  }

  Future<void> _addConnection() async {
    final text = TextEditingController();
    final l = AppL10n.of(context);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.localTransferAddDevice),
        content: TextField(
          controller: text,
          decoration: InputDecoration(hintText: l.localTransferConnectionHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, text.text),
            child: Text(l.localTransferAddDevice),
          ),
        ],
      ),
    );
    // The dialog's outgoing animation may still use its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    text.dispose();
    if (value == null || !mounted) return;
    try {
      _engine?.addPeer(LanPeer.parseLink(value));
    } catch (_) {
      _message(l.localTransferConnectionInvalid);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    final engine = _engine;
    if (engine?.busy != true) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _leaving = true;
    final l = AppL10n.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.localTransferLeaveTitle),
        content: Text(l.localTransferLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.localTransferStopAndLeave),
          ),
        ],
      ),
    );
    if (exit == true) {
      await engine!.cancel();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    }
    _leaving = false;
  }

  String _phase(AppL10n l, LanTransferPhase phase) => switch (phase) {
        LanTransferPhase.idle => l.localTransferReady,
        LanTransferPhase.preparing => l.localTransferPreparing,
        LanTransferPhase.waiting => l.localTransferWaiting,
        LanTransferPhase.sending => l.localTransferSending,
        LanTransferPhase.receiving => l.localTransferReceiving,
        LanTransferPhase.verifying => l.localTransferVerifying,
        LanTransferPhase.completed => l.localTransferCompleted,
        LanTransferPhase.failed => l.localTransferFailed,
        LanTransferPhase.cancelled => l.localTransferCancelled,
      };
  String _failure(AppL10n l, String? code) => switch (code) {
        'rejected' => l.localTransferRejected,
        'busy' => l.localTransferBusy,
        'integrity' => l.localTransferIntegrityError,
        'file' => l.localTransferFileError,
        'timeout' => l.localTransferTimeout,
        'cancelled' => l.localTransferCancelled,
        _ => l.localTransferNetworkError,
      };
  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border.all(color: AppTokens.gray200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _collapsibleCard(String id, String title, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border.all(color: AppTokens.gray200),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey(id),
          minTileHeight: 48,
          visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          children: children,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), engine = _engine;
    ref.listen(accountStoreProvider, (before, after) {
      if (before?.valueOrNull?.currentAccountId !=
          after.valueOrNull?.currentAccountId) {
        unawaited(_engine?.cancel() ?? Future.value());
        if (mounted) Navigator.maybePop(context);
      }
    });
    final offer = engine?.incoming;
    return PopScope(
      canPop: engine?.busy != true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: AppTokens.canvas,
        body: SafeArea(
          child: Column(
            children: [
              LegacyTitleBar(
                title: l.localTransferTitle,
                trailing: IconButton(
                  tooltip: l.localTransferStorageSettings,
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  onPressed:
                      engine == null || engine.busy || _savingFile != null
                          ? null
                          : _storageSettings,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: _leave,
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          if (_storageWarning)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(l.localTransferStorageFallback,
                                  style: TextStyle(color: AppTokens.gray600)),
                            ),
                          if (_error != null)
                            _card([
                              Text(l.localTransferNetworkError),
                              TextButton(
                                onPressed: _start,
                                child: Text(l.actionRetry),
                              ),
                            ]),
                          if (engine != null) ...[
                            _card([
                              Row(children: [
                                const Icon(Icons.devices_outlined, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(safeText(_identity!.name),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          _identity!.addresses.isEmpty
                                              ? l.localTransferNetworkError
                                              : _identity!.addresses
                                                  .map((a) => a.address)
                                                  .join(' · '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.gray500)),
                                    ])),
                                IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: l.localTransferCopyConnection,
                                    onPressed: _identity!.addresses.isEmpty
                                        ? null
                                        : _copyConnection,
                                    icon: const Icon(Icons.copy_outlined,
                                        size: 20)),
                              ]),
                            ]),
                            if (offer != null)
                              _card([
                                Text(
                                  l.localTransferIncoming,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(safeText(offer.senderName)),
                                Text(
                                  '${l.localTransferCode}: ${offer.verificationCode}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(l.localTransferCompareCode),
                                const SizedBox(height: 8),
                                for (final file in offer.files)
                                  Text(
                                    '${safeText(file.name)} · ${formatBytes(file.size)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => engine.respond(false),
                                      child: Text(l.localTransferReject),
                                    ),
                                    FilledButton(
                                      onPressed: () => engine.respond(true),
                                      child: Text(l.localTransferAccept),
                                    ),
                                  ],
                                ),
                              ]),
                            if (engine.phase != LanTransferPhase.idle &&
                                offer == null)
                              _card([
                                Text(
                                  _phase(l, engine.phase),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (engine.peerName != null)
                                  Text(safeText(engine.peerName)),
                                if (engine.verificationCode != null &&
                                    engine.busy) ...[
                                  Text(
                                    '${l.localTransferCode}: ${engine.verificationCode}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(l.localTransferCompareCode),
                                ],
                                if (engine.currentFileName != null)
                                  Text(
                                    safeText(engine.currentFileName),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                if (engine.busy)
                                  LinearProgressIndicator(
                                    value: engine.total <= 0
                                        ? null
                                        : (engine.transferred / engine.total)
                                            .clamp(0, 0.99),
                                  ),
                                if (engine.total > 0)
                                  Text(
                                    '${formatBytes(engine.transferred)} / ${formatBytes(engine.total)}',
                                  ),
                                if (engine.phase == LanTransferPhase.failed)
                                  Text(_failure(l, engine.errorCode)),
                                if (engine.busy)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: engine.cancel,
                                      child: Text(l.actionCancel),
                                    ),
                                  ),
                              ]),
                            _card([
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.localTransferSelected,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        engine.busy || _picking ? null : _pick,
                                    icon: const Icon(Icons.attach_file),
                                    label: Text(l.localTransferChooseFiles),
                                  ),
                                ],
                              ),
                              for (var i = 0; i < _selected.length; i++)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                    Icons.insert_drive_file_outlined,
                                  ),
                                  title: Text(
                                    safeText(
                                      _selected[i].uri.pathSegments.last,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: engine.busy
                                        ? null
                                        : () => setState(
                                              () => _selected.removeAt(i),
                                            ),
                                  ),
                                ),
                              const Divider(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.localTransferNearby,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        engine.busy ? null : _addConnection,
                                    child: Text(l.localTransferAddDevice),
                                  ),
                                ],
                              ),
                              if (engine.peers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(l.localTransferNoDevices),
                                ),
                              for (final peer in engine.peers)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.devices_outlined),
                                  title: Text(safeText(peer.name)),
                                  subtitle: Text(peer.address.address),
                                  trailing: TextButton(
                                    onPressed: engine.busy || _selected.isEmpty
                                        ? null
                                        : () => _send(peer),
                                    child: Text(l.actionSend),
                                  ),
                                ),
                            ]),
                            if (engine.received.isNotEmpty)
                              _collapsibleCard('local-transfer-received',
                                  l.localTransferReceived, [
                                Text(
                                  l.localTransferReceivedHint,
                                  style: TextStyle(color: AppTokens.gray500),
                                ),
                                const SizedBox(height: 8),
                                for (final item in engine.received.take(50))
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.insert_drive_file_outlined,
                                    ),
                                    title: Text(
                                      safeText(item.name),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${formatBytes(item.size)} · ${item.location ?? l.localTransferPrivateStorage}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: TextButton.icon(
                                      icon: const Icon(Icons.save_as_outlined,
                                          size: 20),
                                      label: Text(l.localTransferSave),
                                      onPressed: _savingFile != null
                                          ? null
                                          : () => _saveReceived(item),
                                    ),
                                  ),
                              ]),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
