import '../background/background_lifecycle.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/account_store.dart';
import '../storage/secure_token_store.dart';
import '../storage/server_store.dart';
import '../utils/app_log.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/messages/data/message_cache.dart';
import '../../features/messages/domain/message_models.dart';

part 'sse_client.g.dart';

// ---------------------------------------------------------------------------
// VoceSseClient
// ---------------------------------------------------------------------------
//
// We talk to `/api/user/events_ws` — the server's WebSocket twin of the SSE
// `/api/user/events` endpoint. Same JSON envelopes, but each message is its
// own WebSocket text frame, so there's no chunked-transfer + gzip + line-
// splitter dance. This avoids the Windows-desktop SSE buffering problem we
// hit with the HTTP-based clients.
//
// Liveness model: mirrors web `useStreaming.ts`. Server emits `heartbeat`
// events every ~15s; the client runs a 20s dead-man's-switch watchdog
// reset on every received event. When the watchdog fires, the socket is
// torn down and `onDone` triggers the normal reconnect path. This catches
// silent NAT/firewall drops where TCP keepalive hasn't yet surfaced the
// failure.

/// Watchdog timeout — must be at least the server's heartbeat period (15s)
/// plus jitter. Web uses 20s; mirror that.
const Duration _kSseWatchdog = Duration(seconds: 20);

/// Hard cap on a single `WebSocket.connect` handshake. On a silently-dropped
/// idle link (NAT/firewall reaped the TCP flow without an RST) the SYN of a
/// reconnect goes nowhere and the handshake hangs *forever* — there is no
/// default timeout on `WebSocket.connect`. Without this, a watchdog-driven
/// reconnect can deadlock the whole stream: the old socket never errored, the
/// new one never completes, and no further reconnect is ever scheduled. This
/// timeout converts that hang into a normal "connect failed → backoff retry".
const Duration _kConnectTimeout = Duration(seconds: 15);

class VoceSseClient {
  VoceSseClient({
    required this.baseUrl,
    required String apiKey,
    int? initialAfterMid,
    this.refreshToken,
    this.preferInlineParsing,
    this.parseFrame,
    this.onStatusChanged,
  })  : _apiKey = apiKey,
        _highWaterMid = initialAfterMid;

  final String baseUrl;
  final void Function(SseStatus status)? onStatusChanged;

  /// Small background messages do not need a new isolate for each event.
  final bool Function()? preferInlineParsing;

  @visibleForTesting
  final Future<ChatEvent> Function(String type, String raw)? parseFrame;

  /// Called at the start of every (re)connect attempt. If it returns a
  /// non-null, non-empty string the returned value replaces [_apiKey] before
  /// the WebSocket URL is built. Returning null means "no change / renew
  /// failed; continue with current key".
  final Future<String?> Function()? refreshToken;

  /// The access token used in the WebSocket query string and header. Mutated
  /// by [refreshToken] on every connect so reconnects always use a fresh key.
  String _apiKey;

  static const Duration _maxBackoff = Duration(seconds: 30);

  /// Highest message id observed so far. Sent as `after_mid` on every
  /// (re)connect so the server replays anything we missed during a gap.
  int? _highWaterMid;

  WebSocket? _socket;
  HttpClient? _httpClient;
  StreamSubscription<dynamic>? _sub;

  /// Dead-man's-switch: if no event arrives within [_kSseWatchdog] we
  /// assume the link is dead and force a reconnect.
  Timer? _watchdog;
  Timer? _reconnectTimer;

  /// Monotonic connection generation. Bumped on every [_cleanup]. Each
  /// connect attempt captures the generation it was started under; any
  /// callback (onDone/onError/listen/connect-completion) that fires for a
  /// stale generation is ignored. This is what prevents a torn-down socket's
  /// late `onDone` from racing the watchdog's fresh reconnect and spawning a
  /// second, competing reconnect chain (two sockets, two watchdogs clobbering
  /// each other's fields).
  int _generation = 0;

  /// Set when the consumer (provider dispose) tears us down explicitly —
  /// suppresses any in-flight reconnect schedules.
  bool _disposed = false;
  StreamController<ChatEvent>? _eventsController;

  /// Returns a broadcast [Stream<ChatEvent>] with auto-reconnect.
  Stream<ChatEvent> events() {
    if (_disposed) return const Stream.empty();
    final existing = _eventsController;
    if (existing != null) return existing.stream;
    final controller = StreamController<ChatEvent>.broadcast(onCancel: dispose);
    _eventsController = controller;
    _connect(controller, const Duration(seconds: 1));
    return controller.stream;
  }

  /// Close both the transport and the stream. An async generator waiting for
  /// its next event cannot finish cancellation until this stream completes.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cleanup();
    onStatusChanged?.call(SseStatus.disconnected);
    final controller = _eventsController;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }

  /// Force an immediate reconnect (e.g. after network came back or app
  /// resumed from background). Safe to call from outside.
  void forceReconnect(StreamController<ChatEvent> controller) {
    if (_disposed) return;
    AppLog.w(LogTag.sse, () => '🔄 SSE forceReconnect');
    onStatusChanged?.call(SseStatus.reconnecting);
    _cleanup();
    _connect(controller, const Duration(seconds: 1));
  }

  Future<void> _connect(
      StreamController<ChatEvent> controller, Duration currentDelay) async {
    if (_disposed || controller.isClosed) return;

    // Capture the generation this attempt belongs to. _cleanup() bumps
    // _generation, so any callback below that fires after a teardown sees a
    // mismatch and bails — no stale reconnect chains.
    final myGen = _generation;
    bool isStale() => _disposed || controller.isClosed || myGen != _generation;

    // Renew the access token before every (re)connect so reconnects after
    // expiry don't loop with a stale key. A null return means "keep current".
    if (refreshToken != null) {
      final fresh = await refreshToken!();
      if (isStale()) return;
      if (fresh != null && fresh.isNotEmpty) {
        _apiKey = fresh;
      }
    }

    final base = Uri.parse(baseUrl);
    final apiPath = '${base.path.replaceFirst(RegExp(r"/+$"), "")}/api/user';
    final query = <String, String>{
      'api-key': _apiKey,
      if (_highWaterMid != null) 'after_mid': '${_highWaterMid!}',
    };
    final headers = <String, String>{
      'X-API-Key': _apiKey,
      // Match the HTTP API interceptor: licensed servers reject an empty
      // Referer even when the API key itself is valid.
      'Referer': '${base.origin}/',
      'Origin': base.origin,
    };
    final wsUrl = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '$apiPath/events_ws',
      queryParameters: query,
    );
    WebSocket? socket;
    HttpClient? http;
    late Stream<dynamic> frames;
    try {
      try {
        socket = await WebSocket.connect(wsUrl.toString(), headers: headers)
            .timeout(_kConnectTimeout);
        frames = socket;
      } on WebSocketException catch (error) {
        // Older servers and some reverse proxies only expose the original
        // HTTP event stream. Authentication/license failures still fail;
        // switching transports must not bypass those responses.
        final status = error.httpStatusCode;
        if (!const {400, 404, 405, 426, 501}.contains(status)) rethrow;
        if (isStale()) return;
        http = HttpClient()..connectionTimeout = _kConnectTimeout;
        final uri =
            base.replace(path: '$apiPath/events', queryParameters: query);
        final request = await http.getUrl(uri).timeout(_kConnectTimeout);
        headers.forEach(request.headers.set);
        request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        final response = await request.close().timeout(_kConnectTimeout);
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException('Event stream HTTP ${response.statusCode}');
        }
        frames = decodeVoceEventStream(response.map((chunk) {
          if (!isStale()) _armWatchdog(controller);
          return chunk;
        }));
      }
    } catch (error) {
      http?.close(force: true);
      // Never print a handshake exception's URL: it contains the API key.
      AppLog.w(
          LogTag.sse, () => 'Event connection failed (${error.runtimeType})');
      if (!isStale()) _scheduleReconnect(controller, currentDelay);
      return;
    }
    if (isStale()) {
      socket?.close().catchError((_) {});
      http?.close(force: true);
      return;
    }
    socket?.pingInterval = const Duration(seconds: 30);
    _socket = socket;
    _httpClient = http;

    bool firstFrame = true;
    bool receivedEvent = false;
    _armWatchdog(controller);
    // Serialize asynchronous parsing: a small delta must never overtake the
    // initial snapshot and then be overwritten by that older snapshot.
    _sub = frames.asyncMap<ChatEvent?>((frame) async {
      if (isStale()) return null;
      // Any frame at all means the link is alive. Reset the watchdog.
      _armWatchdog(controller);
      if (firstFrame) {
        firstFrame = false;
        currentDelay = const Duration(seconds: 1);
      }
      final raw = frame is String
          ? frame
          : (frame is List<int> ? utf8.decode(frame) : frame.toString());
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      final eventType = _peekTypeField(trimmed) ?? '';

      ChatEvent chatEvent;
      if (eventType == 'ready' ||
          eventType == 'heartbeat' ||
          eventType == 'kick') {
        chatEvent = parseSseEvent(eventType, trimmed);
      } else {
        try {
          if (parseFrame != null) {
            chatEvent = await parseFrame!(eventType, trimmed);
          } else if (trimmed.length <= 16384 &&
              preferInlineParsing?.call() == true) {
            chatEvent = parseSseEvent(eventType, trimmed);
          } else {
            chatEvent = await compute(
              _parseSseEventInIsolate,
              [eventType, trimmed],
              debugLabel: 'parseSseEvent',
            );
          }
        } catch (_) {
          chatEvent = ChatEvent.unknown(type: eventType, raw: trimmed);
        }
        if (isStale()) return null;
      }

      if (chatEvent is ChatEventChat) {
        final mid = chatEvent.message.mid;
        if (mid > 0 && (_highWaterMid == null || mid > _highWaterMid!)) {
          _highWaterMid = mid;
        }
      }
      return chatEvent;
    }).listen(
      (chatEvent) {
        if (chatEvent != null && !isStale()) {
          if (!receivedEvent &&
              (chatEvent is! ChatEventUnknown || chatEvent.type.isNotEmpty)) {
            receivedEvent = true;
            onStatusChanged?.call(SseStatus.connected);
          }
          controller.add(chatEvent);
        }
      },
      onError: (e) {
        AppLog.w(LogTag.sse, () => '⚠️ SSE socket error: $e');
        if (isStale()) return;
        _scheduleReconnect(controller, currentDelay);
      },
      onDone: () {
        AppLog.w(LogTag.sse, () => '🔌 SSE socket closed');
        if (isStale()) return;
        _scheduleReconnect(controller, currentDelay);
      },
      cancelOnError: false,
    );
  }

  void _armWatchdog(StreamController<ChatEvent> controller) {
    _watchdog?.cancel();
    _watchdog = Timer(_kSseWatchdog, () {
      if (_disposed || controller.isClosed) return;
      onStatusChanged?.call(SseStatus.reconnecting);
      AppLog.w(
          LogTag.sse,
          () =>
              '⏱️ SSE watchdog fired — no events for ${_kSseWatchdog.inSeconds}s, reconnecting');
      _cleanup();
      // Reset backoff: this is a heartbeat-miss, not a hard error.
      _connect(controller, const Duration(seconds: 1));
    });
  }

  void _scheduleReconnect(
      StreamController<ChatEvent> controller, Duration delay) {
    if (_disposed || controller.isClosed) return;
    onStatusChanged?.call(SseStatus.reconnecting);
    _cleanup();
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_disposed || controller.isClosed) return;
      final nextDelay = delay * 2;
      final capped = nextDelay > _maxBackoff ? _maxBackoff : nextDelay;
      _connect(controller, capped);
    });
  }

  void _cleanup() {
    // Invalidate the current generation so any in-flight connect attempt and
    // any still-queued onDone/onError/listen callback from the socket we're
    // tearing down become no-ops (see isStale() in _connect).
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _watchdog?.cancel();
    _watchdog = null;
    final subscription = _sub;
    _sub = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object _) {}));
    }
    _httpClient?.close(force: true);
    _httpClient = null;
    _socket?.close().catchError((_) {});
    _socket = null;
  }
}

// ---------------------------------------------------------------------------
// SSE connection status — UI can show a "reconnecting…" capsule etc.
// ---------------------------------------------------------------------------

enum SseStatus { idle, connecting, connected, disconnected, reconnecting }

@Riverpod(keepAlive: true)
class SseConnectionStatus extends _$SseConnectionStatus {
  @override
  SseStatus build() => SseStatus.idle;

  // ignore: use_setters_to_change_properties
  void set(SseStatus value) => state = value;
}

// ---------------------------------------------------------------------------
// SSE provider
// ---------------------------------------------------------------------------
//
// `keepAlive: true` because [MessageDispatcher] is the canonical long-lived
// listener; AutoDispose would otherwise teardown/restart the WebSocket every
// time the listener set transiently empties.
//
// The provider rebuilds (closing the old WebSocket, opening a new one)
// whenever any of these change:
//   - auth state (sign-in / sign-out)
//   - current server
//   - stored tokens for the current server (token refresh)
// This is what makes "refresh → SSE picks up new token automatically" work.

@Riverpod(keepAlive: true)
Stream<ChatEvent> sseEvents(Ref ref) async* {
  var disposed = false;
  VoceSseClient? activeClient;
  ref.onDispose(() {
    disposed = true;
    activeClient?.dispose();
  });
  // Only stream when authenticated. Watching authController makes the
  // provider rebuild on login/logout.
  final authState = await ref.watch(authControllerProvider.future);
  if (disposed) return;
  if (authState is! AuthStateAuthenticated) {
    return;
  }

  // Watching accountStore makes the provider rebuild on account switch (same
  // or different server); watching serverStore makes it rebuild on server
  // switch too, since that's what resolves currentServer's baseUrl.
  final accountState = await ref.watch(accountStoreProvider.future);
  if (disposed) return;
  final accountId = accountState.currentAccountId;
  if (accountId == null) return;
  final serverState = await ref.watch(serverStoreProvider.future);
  if (disposed) return;
  final account =
      accountState.accounts.where((a) => a.accountId == accountId).firstOrNull;
  if (account == null) return;
  final currentServer =
      serverState.servers.where((s) => s.id == account.serverId).firstOrNull;
  if (currentServer == null) return;

  // Token. We READ rather than WATCH here because the token store doesn't
  // expose a stream; instead we manually invalidate this provider when a
  // refresh happens (see SseTokenWatcher below).
  final tokenStore = ref.read(secureTokenStoreProvider(accountId));
  final tokens = await tokenStore.readTokens();
  if (disposed) return;
  if (tokens == null) return;

  final cache = await ref.read(messageCacheProvider.future);
  if (disposed) return;
  final cursor = await cache.getCursor();
  if (disposed) return;

  // Callback invoked at the start of every (re)connect. Re-reads the current
  // token and proactively renews it if it is within 30s of expiry — mirroring
  // web `useStreaming.ts`'s per-connect renew. Returning null tells the client
  // to keep its existing key and proceed (preserves backoff/retry behaviour).
  Future<String?> tokenRefreshCallback() async {
    if (disposed) return null;
    final store = ref.read(secureTokenStoreProvider(accountId));
    final current = await store.readTokens();
    if (disposed || current == null) return null;
    final aboutToExpire = current.expiresAt
        .isBefore(DateTime.now().add(const Duration(seconds: 30)));
    if (aboutToExpire) {
      AppLog.w(LogTag.sse,
          () => '🔑 SSE: token within 30s of expiry, renewing before connect');
      final renewed =
          await ref.read(authControllerProvider.notifier).renewIfPossible();
      if (disposed) return null;
      if (!renewed) {
        AppLog.w(LogTag.sse,
            () => '🔑 SSE: token renew failed, proceeding with current key');
        return null;
      }
      final fresh = await store.readTokens();
      return disposed ? null : fresh?.accessToken;
    }
    return current.accessToken;
  }

  final client = VoceSseClient(
    baseUrl: currentServer.baseUrl,
    apiKey: tokens.accessToken,
    initialAfterMid: cursor,
    refreshToken: tokenRefreshCallback,
    preferInlineParsing: () =>
        !disposed && ref.read(androidBackgroundedProvider),
    onStatusChanged: (status) {
      if (!disposed) {
        ref.read(sseConnectionStatusProvider.notifier).set(status);
      }
    },
  );

  activeClient = client;

  // Forward connection-status transitions to the UI provider.
  ref.read(sseConnectionStatusProvider.notifier).set(SseStatus.connecting);

  await for (final event in client.events()) {
    if (disposed) return;
    yield event;
  }

  // Stream exhausted (consumer cancelled / provider rebuilding).
  if (!disposed) {
    ref.read(sseConnectionStatusProvider.notifier).set(SseStatus.disconnected);
  }
}

/// Decode SSE records across arbitrary TCP and UTF-8 boundaries. Some servers
/// put the discriminator in `event:` rather than in the JSON body.
@visibleForTesting
Stream<String> decodeVoceEventStream(Stream<List<int>> bytes) async* {
  var event = '';
  var data = <String>[];
  String? record() {
    if (data.isEmpty) return null;
    final raw = data.join('\n');
    if (event.isEmpty || _peekTypeField(raw) != null) return raw;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return jsonEncode({...decoded, 'type': event});
      }
    } catch (_) {}
    return raw;
  }

  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final raw = record();
      if (raw != null) yield raw;
      event = '';
      data = [];
    } else if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final value = line.substring(5);
      data.add(value.startsWith(' ') ? value.substring(1) : value);
    }
  }
  final raw = record();
  if (raw != null) yield raw;
}

/// Top-level (must be top-level for `compute`) parser dispatched to a
/// background isolate so JSON decoding never blocks the UI thread.
ChatEvent _parseSseEventInIsolate(List<String> args) {
  return parseSseEvent(args[0], args[1]);
}

/// Read the top-level `"type"` field from a raw SSE/WS JSON envelope.
///
/// Important: chat envelopes embed a `detail.type` ("normal", "reply",
/// "edit", …) BEFORE the outer `"type":"chat"` in the wire order, so a
/// naive "first match" regex picks the wrong one. We instead do a real
/// JSON decode for the discriminator — small price for correctness, and
/// the heavy decode still happens later inside the isolate.
String? _peekTypeField(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      final t = decoded['type'];
      if (t is String) return t;
    }
  } catch (_) {}
  return null;
}
