import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

String _nonce() => List.generate(16, (_) => Random.secure().nextInt(256))
    .map((e) => e.toRadixString(16).padLeft(2, '0'))
    .join();

bool isPrivateLanAddress(InternetAddress address,
    {bool allowLoopback = false}) {
  if (address.type != InternetAddressType.IPv4) return false;
  final a = address.rawAddress;
  return (allowLoopback && address.isLoopback) ||
      a[0] == 10 ||
      (a[0] == 192 && a[1] == 168) ||
      (a[0] == 172 && a[1] >= 16 && a[1] <= 31);
}

String safeTransferName(String name) {
  final value = name
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[\x00-\x1f\x7f<>:"|?*]'), '_')
      .trim();
  if (value.isEmpty || value == '.' || value == '..') return 'file';
  if (utf8.encode(value).length <= 220) return value;
  final dot = value.lastIndexOf('.');
  final suffix =
      dot > 0 && value.length - dot <= 16 ? value.substring(dot) : '';
  final output = StringBuffer();
  var length = 0;
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    final bytes = utf8.encode(character).length;
    if (length + bytes > 170) break;
    output.write(character);
    length += bytes;
  }
  return '${output}_file$suffix';
}

class LanPeer {
  const LanPeer(
      {required this.fingerprint,
      required this.name,
      required this.address,
      required this.port,
      required this.lastSeen,
      this.manual = false});
  final String fingerprint, name;
  final InternetAddress address;
  final int port;
  final DateTime lastSeen;
  final bool manual;
  Uri get link => Uri(
      scheme: 'vocechat-transfer',
      host: address.address,
      port: port,
      queryParameters: {'fp': fingerprint, 'name': name});
  static LanPeer parseLink(String link, {bool allowLoopback = false}) {
    final uri = Uri.parse(link.trim());
    final address = InternetAddress.tryParse(uri.host);
    final fp = uri.queryParameters['fp'] ?? '';
    if (uri.scheme != 'vocechat-transfer' ||
        address == null ||
        !isPrivateLanAddress(address, allowLoopback: allowLoopback) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(fp) ||
        uri.port < 1 ||
        uri.port > 65535) {
      throw const LanTransferException('protocol');
    }
    return LanPeer(
        fingerprint: fp,
        name: _alias(uri.queryParameters['name']),
        address: address,
        port: uri.port,
        lastSeen: DateTime.now(),
        manual: true);
  }
}

String _alias(Object? name) {
  if (name is! String) return 'VoceChat';
  final value = name.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
  return value.isEmpty ? 'VoceChat' : value.substring(0, min(64, value.length));
}

class LanTransferException implements Exception {
  const LanTransferException(this.code);
  final String code;
}

enum LanTransferPhase {
  idle,
  preparing,
  waiting,
  sending,
  receiving,
  verifying,
  completed,
  failed,
  cancelled
}

class LanFileDescription {
  const LanFileDescription(this.id, this.name, this.size, this.hash);
  final String id, name, hash;
  final int size;
  Map<String, Object> toJson() =>
      {'id': id, 'name': name, 'size': size, 'sha256': hash};
  factory LanFileDescription.fromJson(Object? value) {
    if (value is! Map) throw const LanTransferException('protocol');
    final id = value['id'],
        name = value['name'],
        size = value['size'],
        hash = value['sha256'];
    if (id is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        name is! String ||
        name.length > 512 ||
        size is! int ||
        size < 0 ||
        size > (1 << 40) ||
        hash is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw const LanTransferException('protocol');
    }
    return LanFileDescription(id, safeTransferName(name), size, hash);
  }
}

class LanIncomingOffer {
  const LanIncomingOffer(this.senderName, this.verificationCode, this.files);
  final String senderName, verificationCode;
  final List<LanFileDescription> files;
}

class LanReceivedFile {
  const LanReceivedFile(this.file, this.name, this.size);
  final File file;
  final String name;
  final int size;
}

class _IncomingSession {
  _IncomingSession(this.id, this.token, this.files);
  final String id, token;
  final List<LanFileDescription> files;
  final completed = <String>{};
  final approval = Completer<bool>();
  bool accepted = false, writing = false;
  HttpRequest? request;
  StreamController<List<int>>? input;
  StreamSubscription<List<int>>? subscription;
  File? partial;
  Timer? idle;
}

/// Independent, versioned LAN protocol. No VoceChat tokens or server API calls.
/// TLS certificates are ephemeral and pinned to the selected discovery record.
class LanTransferEngine extends ChangeNotifier {
  LanTransferEngine(
      {required this.context,
      required this.fingerprint,
      required String name,
      required this.directory,
      this.broadcasts = const [],
      this.allowLoopback = false,
      this.onIncoming,
      this.onActive,
      this.discoveryPort = 53318})
      : name = _alias(name);
  final SecurityContext context;
  final String fingerprint, name;
  final Directory directory;
  final List<InternetAddress> broadcasts;
  final bool allowLoopback;
  final int discoveryPort;
  final Future<bool> Function(LanIncomingOffer)? onIncoming;
  final Future<void> Function(bool active, int progress)? onActive;
  HttpServer? _server;
  RawDatagramSocket? _discovery;
  Timer? _announce;
  final _peers = <String, LanPeer>{};
  final received = <LanReceivedFile>[];
  LanTransferPhase phase = LanTransferPhase.idle;
  LanIncomingOffer? incoming;
  String? peerName, currentFileName, errorCode, verificationCode;
  int transferred = 0, total = 0;
  bool _working = false, _closed = false;
  int _generation = 0, _lastPercent = -2;
  _IncomingSession? _session;
  HttpClient? _client;
  LanPeer? _outgoingPeer;
  String? _outgoingId, _outgoingToken;
  Future<void> _platformQueue = Future.value();
  bool _discoveryEnabled = true;
  bool get busy => _working;
  int get port => _server!.port;
  List<LanPeer> get peers =>
      _peers.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  static String certificateFingerprint(String pem) => sha256
      .convert(base64Decode(pem.replaceAll(RegExp(r'-----[^-]+-----|\s'), '')))
      .toString();
  static String pairingCode(String first, String second, String sessionToken) {
    final pair = [first, second]..sort();
    // Bind the human check to this TLS-protected offer, not merely the public
    // discovery fingerprints, which any nearby device can observe and repeat.
    final hash =
        sha256.convert(utf8.encode('${pair.join(':')}:$sessionToken')).bytes;
    return (((hash[0] << 16) | (hash[1] << 8) | hash[2]) % 1000000)
        .toString()
        .padLeft(6, '0');
  }

  Future<void> start({bool discovery = true}) async {
    await directory.create(recursive: true);
    await for (final item in directory.list()) {
      final partial = RegExp(r'^\.[a-f0-9]{32}_[a-f0-9]{32}\.part$')
          .hasMatch(item.uri.pathSegments.last);
      if (item is File && !partial) {
        received.add(LanReceivedFile(
            item, item.uri.pathSegments.last, await item.length()));
      } else if (item is File && partial) {
        await item.delete();
      }
    }
    received.sort((a, b) =>
        b.file.lastModifiedSync().compareTo(a.file.lastModifiedSync()));
    _server = await HttpServer.bindSecure(InternetAddress.anyIPv4, 0, context);
    if (_closed) {
      await _server!.close(force: true);
      return;
    }
    _server!.listen((request) => unawaited(_handle(request)),
        onError: (Object _) {});
    if (discovery) {
      try {
        _discovery = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, discoveryPort,
            reuseAddress: true, reusePort: true);
        _discovery!.broadcastEnabled = true;
        _discovery!.multicastLoopback = false;
        final group = InternetAddress('239.77.18.1');
        for (final network
            in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
          if (network.addresses.any((a) => isPrivateLanAddress(a))) {
            try {
              _discovery!.joinMulticast(group, network);
            } catch (_) {}
          }
        }
        _discovery!.listen((event) {
          if (event != RawSocketEvent.read) return;
          Datagram? packet;
          while ((packet = _discovery!.receive()) != null) {
            _acceptPacket(packet!);
          }
        }, onError: (Object _) {});
        _announce =
            Timer.periodic(const Duration(seconds: 2), (_) => _publish());
        _publish();
      } catch (_) {/* Manual connection information remains available. */}
    }
    _notify();
  }

  LanPeer selfAt(InternetAddress address) => LanPeer(
      fingerprint: fingerprint,
      name: name,
      address: address,
      port: port,
      lastSeen: DateTime.now());
  void addPeer(LanPeer peer) {
    if (!isPrivateLanAddress(peer.address, allowLoopback: allowLoopback) ||
        peer.fingerprint == fingerprint) {
      return;
    }
    if (!_peers.containsKey(peer.fingerprint) && _peers.length >= 64) return;
    _peers[peer.fingerprint] = peer;
    _notify();
  }

  void setDiscoveryEnabled(bool enabled) {
    _discoveryEnabled = enabled;
    if (enabled) _publish();
  }

  void _publish() {
    if (_closed || !_discoveryEnabled) return;
    final now = DateTime.now();
    _peers.removeWhere((_, peer) =>
        !peer.manual && now.difference(peer.lastSeen).inSeconds > 8);
    final data = utf8.encode(jsonEncode({
      'protocol': 'vocechat-lan-1',
      'id': fingerprint,
      'name': name,
      'port': port
    }));
    for (final address in [InternetAddress('239.77.18.1'), ...broadcasts]) {
      try {
        _discovery?.send(data, address, discoveryPort);
      } catch (_) {}
    }
    _notify();
  }

  void _acceptPacket(Datagram packet) {
    if (_closed ||
        !_discoveryEnabled ||
        packet.data.length > 4096 ||
        !isPrivateLanAddress(packet.address, allowLoopback: allowLoopback)) {
      return;
    }
    try {
      final value = jsonDecode(utf8.decode(packet.data));
      if (value is! Map ||
          value['protocol'] != 'vocechat-lan-1' ||
          value['id'] == fingerprint ||
          value['id'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['id'] as String) ||
          value['port'] is! int ||
          value['port'] < 1 ||
          value['port'] > 65535) {
        return;
      }
      addPeer(LanPeer(
          fingerprint: value['id'],
          name: _alias(value['name']),
          address: packet.address,
          port: value['port'],
          lastSeen: DateTime.now()));
    } catch (_) {}
  }

  Future<void> _active(bool active, [int progress = -1]) {
    _platformQueue = _platformQueue.catchError((Object _) {}).then((_) async {
      await onActive?.call(active, progress);
    });
    return _platformQueue;
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void _progress(int bytes) {
    transferred = bytes;
    final percent = total <= 0 ? 0 : (bytes * 100 ~/ total).clamp(0, 99);
    if (percent != _lastPercent) {
      _lastPercent = percent;
      unawaited(_active(true, percent).catchError((Object _) {}));
      _notify();
    }
  }

  HttpClient _http(LanPeer peer) {
    if (!isPrivateLanAddress(peer.address, allowLoopback: allowLoopback)) {
      throw const LanTransferException('network');
    }
    return HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..connectionTimeout = const Duration(seconds: 10)
      ..autoUncompress = false
      ..badCertificateCallback = (certificate, host, port) =>
          host == peer.address.address &&
          port == peer.port &&
          sha256.convert(certificate.der).toString() == peer.fingerprint;
  }

  Uri _uri(LanPeer peer, String path) => Uri(
      scheme: 'https', host: peer.address.address, port: peer.port, path: path);
  Future<Object?> _post(
      HttpClient client, LanPeer peer, String path, Object data,
      {String? token}) async {
    final request = await client.postUrl(_uri(peer, path));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.write(jsonEncode(data));
    final response = await request.close().timeout(const Duration(seconds: 65));
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw LanTransferException(switch (response.statusCode) {
        403 => 'rejected',
        409 => 'busy',
        408 => 'timeout',
        422 => 'integrity',
        _ => 'network'
      });
    }
    return _json(response);
  }

  Future<dynamic> _json(Stream<List<int>> input) async {
    final buffer = BytesBuilder(copy: false);
    await for (final bytes in input.timeout(const Duration(seconds: 65))) {
      if (buffer.length + bytes.length > 64 * 1024) {
        throw const LanTransferException('protocol');
      }
      buffer.add(bytes);
    }
    return jsonDecode(utf8.decode(buffer.takeBytes()));
  }

  Future<void> sendFiles(LanPeer peer, List<File> files) async {
    if (_working || _closed) return;
    _working = true;
    final generation = ++_generation;
    phase = LanTransferPhase.preparing;
    errorCode = null;
    peerName = peer.name;
    final offerToken = _nonce() + _nonce();
    verificationCode = pairingCode(fingerprint, peer.fingerprint, offerToken);
    transferred = total = 0;
    _lastPercent = -2;
    _notify();
    void current() {
      if (_closed || generation != _generation) {
        throw const LanTransferException('cancelled');
      }
    }

    HttpClient? client;
    String? sessionId, sessionToken;
    try {
      if (files.isEmpty || files.length > 16) {
        throw const LanTransferException('file');
      }
      await _active(true);
      current();
      final descriptions = <LanFileDescription>[];
      for (final file in files) {
        currentFileName = file.uri.pathSegments.last;
        _notify();
        final size = await file.length();
        if (size > (1 << 40)) throw const LanTransferException('file');
        final hash = await sha256
            .bind(file.openRead().map((chunk) {
              current();
              return chunk;
            }))
            .first;
        current();
        descriptions.add(LanFileDescription(_nonce(),
            safeTransferName(currentFileName!), size, hash.toString()));
      }
      total = descriptions.fold(0, (a, b) => a + b.size);
      client = _client = _http(peer);
      final id = _outgoingId = _nonce(), token = _outgoingToken = offerToken;
      sessionId = id;
      sessionToken = token;
      _outgoingPeer = peer;
      phase = LanTransferPhase.waiting;
      _notify();
      await _post(client, peer, '/v1/offer', {
        'id': id,
        'token': token,
        'sender': name,
        'fingerprint': fingerprint,
        'files': descriptions.map((d) => d.toJson()).toList()
      });
      current();
      phase = LanTransferPhase.sending;
      _notify();
      var sent = 0;
      for (var i = 0; i < files.length; i++) {
        current();
        final description = descriptions[i];
        currentFileName = description.name;
        _notify();
        if (await files[i].length() != description.size) {
          throw const LanTransferException('file');
        }
        final request =
            await client.putUrl(_uri(peer, '/v1/file/$id/${description.id}'));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.contentType = ContentType.binary;
        request.contentLength = description.size;
        var thisFile = 0;
        await request.addStream(files[i].openRead().map((chunk) {
          current();
          thisFile += chunk.length;
          _progress(sent + thisFile);
          return chunk;
        }));
        final response =
            await request.close().timeout(const Duration(seconds: 120));
        if (response.statusCode != 200) {
          await response.drain<void>();
          throw LanTransferException(
              response.statusCode == 422 ? 'integrity' : 'network');
        }
        await response.drain<void>();
        current();
        sent += description.size;
      }
      await _post(client, peer, '/v1/complete/$id', {}, token: token);
      current();
      phase = LanTransferPhase.completed;
      transferred = total;
    } catch (error) {
      if (!_closed && generation == _generation) {
        phase = LanTransferPhase.failed;
        errorCode = _error(error);
      }
      if (sessionId != null && sessionToken != null) {
        unawaited(_sendCancel(peer, sessionId, sessionToken));
      }
    } finally {
      client?.close(force: true);
      if (generation == _generation) {
        _client = null;
        _outgoingPeer = null;
        _outgoingId = _outgoingToken = null;
        _working = false;
        await _active(false).catchError((Object _) {});
        _notify();
      }
    }
  }

  Future<void> _reply(HttpResponse response, int status,
      [Object value = const {'ok': true}]) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(value));
    await response.close();
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final remote = request.connectionInfo?.remoteAddress;
      if (_closed ||
          remote == null ||
          !isPrivateLanAddress(remote, allowLoopback: allowLoopback)) {
        await _reply(request.response, 403);
        return;
      }
      final parts = request.uri.pathSegments;
      if (request.method == 'POST' && request.uri.path == '/v1/offer') {
        await _offer(request);
        return;
      }
      final session = _session;
      if (parts.length < 3 ||
          parts[0] != 'v1' ||
          session == null ||
          parts[2] != session.id ||
          request.headers.value(HttpHeaders.authorizationHeader) !=
              'Bearer ${session.token}') {
        await _reply(request.response, 401);
        return;
      }
      if (request.method == 'POST' &&
          parts[1] == 'cancel' &&
          parts.length == 3) {
        await _reply(request.response, 200);
        await _cancelIncoming(session, 'cancelled');
        return;
      }
      if (!session.accepted) {
        await _reply(request.response, 403);
        return;
      }
      if (request.method == 'PUT' && parts[1] == 'file' && parts.length == 4) {
        await _receive(request, session, parts[3]);
        return;
      }
      if (request.method == 'POST' &&
          parts[1] == 'complete' &&
          parts.length == 3 &&
          !session.writing &&
          session.completed.length == session.files.length) {
        _session = null;
        session.idle?.cancel();
        _working = false;
        phase = LanTransferPhase.completed;
        transferred = total;
        _notify();
        await _reply(request.response, 200);
        // The receiver may be retained only by its transfer service. Send the
        // final acknowledgement before stopping that service/Flutter engine.
        await _active(false).catchError((Object _) {});
        return;
      }
      await _reply(request.response, 409);
    } catch (error) {
      try {
        await _reply(
            request.response, error is LanTransferException ? 400 : 500);
      } catch (_) {}
    }
  }

  Future<void> _offer(HttpRequest request) async {
    if (_working) {
      await _reply(request.response, 409);
      return;
    }
    // Reserve the slot before reading so concurrent requests cannot both win.
    _working = true;
    _IncomingSession? session;
    try {
      final body = await _json(request);
      if (body is! Map ||
          body['id'] is! String ||
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(body['id']) ||
          body['token'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(body['token']) ||
          body['fingerprint'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(body['fingerprint']) ||
          body['files'] is! List ||
          body['files'].isEmpty ||
          body['files'].length > 16) {
        throw const LanTransferException('protocol');
      }
      final files =
          (body['files'] as List).map(LanFileDescription.fromJson).toList();
      if (files.map((f) => f.id).toSet().length != files.length) {
        throw const LanTransferException('protocol');
      }
      session = _session = _IncomingSession(body['id'], body['token'], files);
      total = files.fold(0, (a, b) => a + b.size);
      transferred = 0;
      _lastPercent = -2;
      peerName = _alias(body['sender']);
      verificationCode =
          pairingCode(fingerprint, body['fingerprint'], body['token']);
      phase = LanTransferPhase.waiting;
      errorCode = null;
      incoming = LanIncomingOffer(
          peerName!, verificationCode!, List.unmodifiable(files));
      _notify();
      final callback = onIncoming;
      if (callback != null) {
        unawaited(callback(incoming!).then((yes) {
          if (!session!.approval.isCompleted) session.approval.complete(yes);
        }));
      }
      final accepted = await session.approval.future
          .timeout(const Duration(seconds: 60), onTimeout: () => false);
      if (_closed || _session != session || !accepted) {
        await _reply(request.response, 403);
        if (_session == session) {
          _session = null;
          incoming = null;
          _working = false;
          phase = LanTransferPhase.idle;
          _notify();
        }
        return;
      }
      await _active(true);
      if (_session != session || _closed) {
        await _reply(request.response, 403);
        return;
      }
      session.accepted = true;
      incoming = null;
      phase = LanTransferPhase.receiving;
      _resetIdle(session);
      _notify();
      await _reply(request.response, 200);
    } catch (_) {
      if (session == null || _session == session) {
        _session = null;
        incoming = null;
        _working = false;
        phase = LanTransferPhase.failed;
        errorCode = 'network';
        await _active(false).catchError((Object _) {});
        _notify();
      }
      rethrow;
    }
  }

  void respond(bool accept) {
    final session = _session;
    if (session != null && !session.approval.isCompleted) {
      session.approval.complete(accept);
    }
  }

  void _resetIdle(_IncomingSession session) {
    session.idle?.cancel();
    session.idle = Timer(const Duration(seconds: 120),
        () => unawaited(_cancelIncoming(session, 'timeout')));
  }

  Future<void> _receive(
      HttpRequest request, _IncomingSession session, String id) async {
    final description = session.files.where((f) => f.id == id).firstOrNull;
    if (description == null ||
        session.writing ||
        session.completed.contains(id) ||
        request.contentLength != description.size) {
      await _reply(request.response, 409);
      return;
    }
    session.writing = true;
    session.request = request;
    currentFileName = description.name;
    final part =
        session.partial = File('${directory.path}/.${session.id}_$id.part');
    final sink = part.openWrite();
    late StreamSubscription<List<int>> subscription;
    final input = session.input = StreamController<List<int>>(
        onPause: () => subscription.pause(),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel());
    subscription = session.subscription = request
        .timeout(const Duration(seconds: 60))
        .listen(input.add, onError: input.addError, onDone: input.close);
    final digest = _DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    var size = 0;
    final completedBytes = transferred;
    try {
      await sink.addStream(input.stream.map((chunk) {
        if (_closed || _session != session) {
          throw const LanTransferException('cancelled');
        }
        size += chunk.length;
        if (size > description.size) {
          throw const LanTransferException('protocol');
        }
        hash.add(chunk);
        _resetIdle(session);
        _progress(completedBytes + size);
        return chunk;
      }));
      await sink.close();
      hash.close();
      if (_closed || _session != session) {
        throw const LanTransferException('cancelled');
      }
      phase = LanTransferPhase.verifying;
      _notify();
      if (size != description.size ||
          digest.value?.toString() != description.hash) {
        throw const LanTransferException('integrity');
      }
      final destination = await _destination(description.name);
      await part.rename(destination.path);
      if (_closed || _session != session) {
        await destination.delete();
        throw const LanTransferException('cancelled');
      }
      received.insert(
          0,
          LanReceivedFile(
              destination, destination.uri.pathSegments.last, size));
      session.completed.add(id);
      transferred = completedBytes + size;
      session.partial = null;
      phase = LanTransferPhase.receiving;
      _notify();
      await _reply(request.response, 200);
    } catch (error) {
      try {
        await sink.close();
      } catch (_) {}
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      if (_session == session) {
        try {
          await _reply(
              request.response,
              error is LanTransferException && error.code == 'integrity'
                  ? 422
                  : 500);
        } catch (_) {}
        await _cancelIncoming(session, _error(error));
      }
    } finally {
      await subscription.cancel();
      if (!input.isClosed) unawaited(input.close());
      session.input = null;
      session.subscription = null;
      session.writing = false;
      session.request = null;
    }
  }

  Future<File> _destination(String name) async {
    final safe = safeTransferName(name);
    for (var i = 0; i < 10000; i++) {
      final dot = safe.lastIndexOf('.');
      final stem = dot > 0 ? safe.substring(0, dot) : safe;
      final ext = dot > 0 ? safe.substring(dot) : '';
      final result =
          File('${directory.path}/${i == 0 ? safe : '$stem ($i)$ext'}');
      if (!await result.exists()) return result;
    }
    return File('${directory.path}/${_nonce()}_$safe');
  }

  Future<void> _cancelIncoming(_IncomingSession session, String code) async {
    if (_session != session) return;
    _session = null;
    session.idle?.cancel();
    incoming = null;
    if (!session.approval.isCompleted) session.approval.complete(false);
    await _stopIncomingIO(session);
    _working = false;
    phase = code == 'cancelled'
        ? LanTransferPhase.cancelled
        : LanTransferPhase.failed;
    errorCode = code;
    await _active(false).catchError((Object _) {});
    _notify();
  }

  Future<void> _stopIncomingIO(_IncomingSession session) async {
    final input = session.input;
    if (input != null && !input.isClosed) {
      input.addError(const LanTransferException('cancelled'));
      unawaited(input.close());
    }
    await session.subscription?.cancel();
    final request = session.request;
    if (request != null) {
      try {
        (await request.response.detachSocket(writeHeaders: false)).destroy();
      } catch (_) {}
    }
    final part = session.partial;
    if (part != null) {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
    }
  }

  Future<void> _sendCancel(LanPeer? peer, String? id, String? token) async {
    if (peer == null || id == null || token == null) return;
    final client = _http(peer);
    try {
      await _post(client, peer, '/v1/cancel/$id', {}, token: token)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
    } finally {
      client.close(force: true);
    }
  }

  Future<void> cancel() async {
    ++_generation;
    final peer = _outgoingPeer, id = _outgoingId, token = _outgoingToken;
    _outgoingPeer = null;
    _outgoingId = _outgoingToken = null;
    _client?.close(force: true);
    _client = null;
    unawaited(_sendCancel(peer, id, token));
    final session = _session;
    if (session != null) await _cancelIncoming(session, 'cancelled');
    _working = false;
    phase = LanTransferPhase.cancelled;
    await _active(false).catchError((Object _) {});
    _notify();
  }

  String _error(Object error) => error is LanTransferException
      ? error.code
      : error is TimeoutException
          ? 'timeout'
          : error is FileSystemException
              ? 'file'
              : 'network';

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    ++_generation;
    _announce?.cancel();
    _discovery?.close();
    _client?.close(force: true);
    final session = _session;
    if (session != null) {
      session.idle?.cancel();
      if (!session.approval.isCompleted) session.approval.complete(false);
      unawaited(_stopIncomingIO(session));
    }
    _session = null;
    unawaited(_active(false).catchError((Object _) {}));
    unawaited(_server?.close(force: true) ?? Future.value());
    super.dispose();
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
