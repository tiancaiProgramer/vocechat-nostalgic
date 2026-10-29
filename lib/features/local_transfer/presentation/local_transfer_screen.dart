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
import '../data/local_transfer_platform.dart';

class LocalTransferScreen extends ConsumerStatefulWidget {
  const LocalTransferScreen({super.key, this.initialFiles = const []});
  final List<String> initialFiles;
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
  final _selected = <File>[];
  int _startGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialFiles.take(16).map(File.new));
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
      if (!mounted || generation != _startGeneration) return;
      await localTransferChannel.invokeMethod('discovery', {'enabled': true});
      engine = LanTransferEngine(
          context: identity.context,
          fingerprint: identity.fingerprint,
          name: identity.name,
          directory: Directory('${root.path}/local_transfers/$scope'),
          broadcasts: identity.broadcasts,
          onActive: (active, progress) => localTransferChannel.invokeMethod(
              'active', {'enabled': active, 'progress': progress}));
      await engine.start();
      if (!mounted || generation != _startGeneration) {
        engine.dispose();
        return;
      }
      _engine?.removeListener(_changed);
      _engine?.dispose();
      _identity = identity;
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
      unawaited(localTransferChannel.invokeMethod(
          'discovery', {'enabled': visible}).catchError((Object _) {}));
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
    localTransferChannel.setMethodCallHandler(null);
    unawaited(localTransferChannel.invokeMethod(
        'discovery', {'enabled': false}).catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking || _engine?.busy == true) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform
          .pickFiles(allowMultiple: true, withData: false);
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
  Future<void> _addConnection() async {
    final text = TextEditingController();
    final l = AppL10n.of(context);
    final value = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(l.localTransferAddDevice),
                content: TextField(
                    controller: text,
                    decoration: InputDecoration(
                        hintText: l.localTransferConnectionHint)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.actionCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, text.text),
                      child: Text(l.localTransferAddDevice))
                ]));
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
                      child: Text(l.actionCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.localTransferStopAndLeave))
                ]));
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border.all(color: AppTokens.gray200),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

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
              child: Column(children: [
            LegacyTitleBar(
                title: l.localTransferTitle,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: _leave)),
            Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(padding: const EdgeInsets.all(16), children: [
                        Text(l.localTransferDescription,
                            style: TextStyle(color: AppTokens.gray600)),
                        const SizedBox(height: 16),
                        if (_error != null)
                          _card([
                            Text(l.localTransferNetworkError),
                            TextButton(
                                onPressed: _start, child: Text(l.actionRetry))
                          ]),
                        if (engine != null) ...[
                          _card([
                            Text(l.localTransferMyDevice,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(safeText(_identity!.name)),
                            const SizedBox(height: 4),
                            Text(
                                _identity!.addresses
                                    .map((a) => a.address)
                                    .join(' · '),
                                style: TextStyle(color: AppTokens.gray500)),
                            if (_identity!.addresses.isEmpty)
                              Text(l.localTransferNetworkError),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                    icon: const Icon(Icons.copy_outlined,
                                        size: 18),
                                    label: Text(l.localTransferCopyConnection),
                                    onPressed: _identity!.addresses.isEmpty
                                        ? null
                                        : () async {
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: engine
                                                        .selfAt(_identity!
                                                            .addresses.first)
                                                        .link
                                                        .toString()));
                                            if (mounted) {
                                              _message(l.localTransferCopied);
                                            }
                                          })),
                          ]),
                          if (offer != null)
                            _card([
                              Text(l.localTransferIncoming,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(safeText(offer.senderName)),
                              Text(
                                  '${l.localTransferCode}: ${offer.verificationCode}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600)),
                              Text(l.localTransferCompareCode),
                              const SizedBox(height: 8),
                              for (final file in offer.files)
                                Text(
                                    '${safeText(file.name)} · ${formatBytes(file.size)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed: () => engine.respond(false),
                                        child: Text(l.localTransferReject)),
                                    FilledButton(
                                        onPressed: () => engine.respond(true),
                                        child: Text(l.localTransferAccept)),
                                  ]),
                            ]),
                          if (engine.phase != LanTransferPhase.idle &&
                              offer == null)
                            _card([
                              Text(_phase(l, engine.phase),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              if (engine.peerName != null)
                                Text(safeText(engine.peerName)),
                              if (engine.verificationCode != null &&
                                  engine.busy) ...[
                                Text(
                                    '${l.localTransferCode}: ${engine.verificationCode}',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600)),
                                Text(l.localTransferCompareCode),
                              ],
                              if (engine.currentFileName != null)
                                Text(safeText(engine.currentFileName),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              if (engine.busy)
                                LinearProgressIndicator(
                                    value: engine.total <= 0
                                        ? null
                                        : (engine.transferred / engine.total)
                                            .clamp(0, 0.99)),
                              if (engine.total > 0)
                                Text(
                                    '${formatBytes(engine.transferred)} / ${formatBytes(engine.total)}'),
                              if (engine.phase == LanTransferPhase.failed)
                                Text(_failure(l, engine.errorCode)),
                              if (engine.busy)
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        onPressed: engine.cancel,
                                        child: Text(l.actionCancel))),
                            ]),
                          _card([
                            Row(children: [
                              Expanded(
                                  child: Text(l.localTransferSelected,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              TextButton.icon(
                                  onPressed:
                                      engine.busy || _picking ? null : _pick,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(l.localTransferChooseFiles))
                            ]),
                            if (_selected.isEmpty)
                              Text(l.localTransferChooseHint,
                                  style: TextStyle(color: AppTokens.gray500)),
                            for (var i = 0; i < _selected.length; i++)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                      Icons.insert_drive_file_outlined),
                                  title: Text(
                                      safeText(
                                          _selected[i].uri.pathSegments.last),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: engine.busy
                                          ? null
                                          : () => setState(
                                              () => _selected.removeAt(i)))),
                          ]),
                          _card([
                            Row(children: [
                              Expanded(
                                  child: Text(l.localTransferNearby,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              TextButton(
                                  onPressed:
                                      engine.busy ? null : _addConnection,
                                  child: Text(l.localTransferAddDevice))
                            ]),
                            Text(l.localTransferNearbyHint,
                                style: TextStyle(color: AppTokens.gray500)),
                            const SizedBox(height: 8),
                            if (engine.peers.isEmpty)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(l.localTransferNoDevices)),
                            for (final peer in engine.peers)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.devices_outlined),
                                  title: Text(safeText(peer.name)),
                                  subtitle: Text(peer.address.address),
                                  trailing: TextButton(
                                      onPressed:
                                          engine.busy || _selected.isEmpty
                                              ? null
                                              : () => engine.sendFiles(
                                                  peer, List.of(_selected)),
                                      child: Text(l.actionSend))),
                          ]),
                          if (engine.received.isNotEmpty)
                            _card([
                              Text(l.localTransferReceived,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              for (final item in engine.received.take(50))
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                        Icons.insert_drive_file_outlined),
                                    title: Text(safeText(item.name),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(formatBytes(item.size)),
                                    trailing: IconButton(
                                        tooltip: l.localTransferSave,
                                        icon:
                                            const Icon(Icons.download_outlined),
                                        onPressed: () => downloadAndSave(
                                            context,
                                            ProviderScope.containerOf(context),
                                            '',
                                            item.name,
                                            cachedFile: item.file))),
                            ]),
                        ],
                      ])),
          ]))),
    );
  }
}
