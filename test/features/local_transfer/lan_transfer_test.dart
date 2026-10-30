import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/local_transfer/data/lan_transfer.dart';
import 'package:vocechat_client/features/local_transfer/data/outgoing_transfer_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late HttpOverrides? originalOverrides;
  late List<({SecurityContext context, String fingerprint})> identities;
  final engines = <LanTransferEngine>[];
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('vc-lan-tests-');
    identities = [];
    for (var i = 0; i < 2; i++) {
      final key = '${root.path}/key$i.pem', cert = '${root.path}/cert$i.pem';
      final result = await Process.run(
        Platform.isWindows ? 'openssl.exe' : '/usr/bin/openssl',
        [
          'req',
          '-x509',
          '-newkey',
          'rsa:2048',
          '-keyout',
          key,
          '-out',
          cert,
          '-days',
          '1',
          '-nodes',
          '-subj',
          '/CN=VoceChat Test',
        ],
      );
      if (result.exitCode != 0) {
        throw StateError('Test certificate generation failed');
      }
      identities.add((
        context: SecurityContext(withTrustedRoots: false)
          ..useCertificateChain(cert)
          ..usePrivateKey(key),
        fingerprint: LanTransferEngine.certificateFingerprint(
          await File(cert).readAsString(),
        ),
      ));
    }
  });
  tearDownAll(() => root.delete(recursive: true));
  setUp(() {
    originalOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
  });
  tearDown(() async {
    for (final engine in engines) {
      engine.dispose();
    }
    engines.clear();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    HttpOverrides.global = originalOverrides;
  });
  var sequence = 0;
  Future<LanTransferEngine> engine(
    int identity, {
    Future<bool> Function(LanIncomingOffer)? accept,
    Future<LanReceivedFile> Function(LanReceivedFile)? store,
  }) async {
    final data = identities[identity];
    final instance = LanTransferEngine(
      context: data.context,
      fingerprint: data.fingerprint,
      name: 'Device $identity',
      directory: Directory('${root.path}/received-${sequence++}'),
      allowLoopback: true,
      onIncoming: accept,
      onReceived: store,
    );
    engines.add(instance);
    await instance.start(discovery: false);
    return instance;
  }

  Future<File> file(String name, int size) async {
    final item = File('${root.path}/source-${sequence++}-$name');
    final handle = await item.open(mode: FileMode.write);
    await handle.truncate(size);
    if (size > 0) {
      await handle.setPosition(size - 1);
      await handle.writeByte(37);
    }
    await handle.close();
    return item;
  }

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 300 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue);
  }

  HttpClient client(LanTransferEngine receiver) =>
      HttpClient(context: SecurityContext(withTrustedRoots: false))
        ..badCertificateCallback = (cert, host, port) =>
            sha256.convert(cert.der).toString() == receiver.fingerprint;
  Future<int> raw(
    HttpClient http,
    LanTransferEngine receiver,
    String method,
    String path, {
    Object? json,
    List<int>? bytes,
    String? token,
  }) async {
    final request = await http.openUrl(
      method,
      Uri.parse('https://127.0.0.1:${receiver.port}$path'),
    );
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (json != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(json));
    }
    if (bytes != null) {
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final response = await request.close();
    final status = response.statusCode;
    await response.drain<void>();
    return status;
  }

  test(
    '150 MiB APK and empty file transfer over pinned TLS with exact SHA256',
    () async {
      final sender = await engine(0);
      final receiver = await engine(
        1,
        accept: (offer) async {
          expect(offer.files.length, 2);
          expect(offer.verificationCode, sender.verificationCode);
          return true;
        },
      );
      final apk = await file('application.apk', 150 * 1024 * 1024 + 19),
          empty = await file('empty.txt', 0);
      final queue = OutgoingTransferQueue()..files.addAll([apk, empty]);
      await queue.send(sender, receiver.selfAt(InternetAddress.loopbackIPv4));
      expect(queue.files, isEmpty);
      expect(sender.phase, LanTransferPhase.completed);
      expect(sender.completedOutgoingPaths, {apk.path, empty.path});
      expect(receiver.phase, LanTransferPhase.completed);
      expect(sender.transferred, 150 * 1024 * 1024 + 19);
      expect(receiver.received.length, 2);
      final saved = receiver.received.firstWhere((f) => f.size > 0);
      expect(
        await sha256.bind(saved.file.openRead()).first,
        await sha256.bind(apk.openRead()).first,
      );
      expect(
        await receiver.directory
            .list()
            .where((f) => f.path.endsWith('.part'))
            .length,
        0,
      );
    },
  );
  test('verification code is symmetric and bound to each protected offer', () {
    final first = identities[0].fingerprint, second = identities[1].fingerprint;
    final code = LanTransferEngine.pairingCode(first, second, 'a' * 64);
    expect(code, LanTransferEngine.pairingCode(second, first, 'a' * 64));
    expect(code, isNot(LanTransferEngine.pairingCode(first, second, 'b' * 64)));
    expect(code, matches(RegExp(r'^\d{6}$')));
  });
  test('declining an offer writes no file', () async {
    final sender = await engine(0),
        receiver = await engine(1, accept: (_) async => false);
    final pending = await file('test.txt', 10);
    final queue = OutgoingTransferQueue()..files.add(pending);
    await queue.send(sender, receiver.selfAt(InternetAddress.loopbackIPv4));
    expect(queue.files, [pending]);
    expect(sender.phase, LanTransferPhase.failed);
    expect(sender.errorCode, 'rejected');
    expect(sender.completedOutgoingPaths, isEmpty);
    expect(receiver.received, isEmpty);
    expect(await receiver.directory.list().length, 0);
  });
  test('wrong certificate pin cannot offer or deliver files', () async {
    var prompted = false;
    final sender = await engine(0),
        receiver = await engine(
          1,
          accept: (_) async {
            prompted = true;
            return true;
          },
        );
    final peer = LanPeer(
      fingerprint: '0' * 64,
      name: 'untrusted',
      address: InternetAddress.loopbackIPv4,
      port: receiver.port,
      lastSeen: DateTime.now(),
    );
    await sender.sendFiles(peer, [await file('test.txt', 10)]);
    expect(sender.phase, LanTransferPhase.failed);
    expect(prompted, isFalse);
    expect(receiver.received, isEmpty);
  });
  test('cancellation while awaiting approval reaches both devices', () async {
    final sender = await engine(0), receiver = await engine(1);
    final task = sender.sendFiles(
      receiver.selfAt(InternetAddress.loopbackIPv4),
      [await file('test.txt', 10)],
    );
    await until(() => receiver.incoming != null);
    await sender.cancel();
    await task;
    await until(() => !receiver.busy);
    expect(sender.phase, LanTransferPhase.cancelled);
    expect(sender.completedOutgoingPaths, isEmpty);
    expect(receiver.received, isEmpty);
  });
  test(
    'receiver cancellation during streaming deletes partial bytes',
    () async {
      final sender = await engine(0),
          receiver = await engine(1, accept: (_) async => true);
      var cancelled = false;
      receiver.addListener(() {
        if (!cancelled &&
            receiver.phase == LanTransferPhase.receiving &&
            receiver.transferred > 1024 * 1024) {
          cancelled = true;
          unawaited(receiver.cancel());
        }
      });
      await sender.sendFiles(receiver.selfAt(InternetAddress.loopbackIPv4), [
        await file('large.apk', 20 * 1024 * 1024),
      ]);
      await until(() => !receiver.busy);
      expect(cancelled, isTrue);
      expect(receiver.received, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(await receiver.directory.list().length, 0);
    },
  );
  test('unauthorized uploads cannot write files', () async {
    final receiver = await engine(1), http = client(receiver);
    addTearDown(() => http.close(force: true));
    expect(
      await raw(
        http,
        receiver,
        'PUT',
        '/v1/file/${'a' * 32}/${'b' * 32}',
        bytes: [1, 2, 3],
      ),
      401,
    );
    expect(await receiver.directory.list().length, 0);
  });
  for (final valid in [true, false]) {
    test('safe destination and hash validation (valid=$valid)', () async {
      final receiver = await engine(1, accept: (_) async => true),
          http = client(receiver);
      addTearDown(() => http.close(force: true));
      final id = 'a' * 32,
          token = 'b' * 64,
          fileId = 'c' * 32,
          data = utf8.encode('known contents');
      expect(
        await raw(
          http,
          receiver,
          'POST',
          '/v1/offer',
          json: {
            'id': id,
            'token': token,
            'sender': 'Test',
            'fingerprint': identities[0].fingerprint,
            'files': [
              {
                'id': fileId,
                'name': '../escape.apk',
                'size': data.length,
                'sha256': valid ? sha256.convert(data).toString() : '0' * 64,
              },
            ],
          },
        ),
        200,
      );
      expect(
        await raw(
          http,
          receiver,
          'PUT',
          '/v1/file/$id/$fileId',
          bytes: data,
          token: token,
        ),
        valid ? 200 : 422,
      );
      if (valid) {
        expect(
          await raw(
            http,
            receiver,
            'POST',
            '/v1/complete/$id',
            json: {},
            token: token,
          ),
          200,
        );
        expect(
          receiver.received.single.file.parent.path,
          receiver.directory.path,
        );
        expect(receiver.received.single.name, 'escape.apk');
      } else {
        expect(receiver.phase, LanTransferPhase.failed);
        expect(receiver.errorCode, 'integrity');
        expect(await receiver.directory.list().length, 0);
      }
    });
  }
  test(
    'duplicate names keep both files and a .part extension survives reopening',
    () async {
      final sender = await engine(0),
          receiver = await engine(1, accept: (_) async => true);
      final source = await file('legitimate.part', 32);
      for (var i = 0; i < 2; i++) {
        await sender.sendFiles(receiver.selfAt(InternetAddress.loopbackIPv4), [
          source,
        ]);
      }
      expect(receiver.received.length, 2);
      expect(receiver.received.map((f) => f.file.path).toSet().length, 2);
      final folder = receiver.directory;
      receiver.dispose();
      engines.remove(receiver);
      final reopened = LanTransferEngine(
        context: identities[1].context,
        fingerprint: identities[1].fingerprint,
        name: 'reopened',
        directory: folder,
        allowLoopback: true,
      );
      engines.add(reopened);
      await reopened.start(discovery: false);
      expect(reopened.received.length, 2);
    },
  );
  test('UDP discovery accepts a nearby versioned announcement', () async {
    final probe = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    probe.close();
    final instance = LanTransferEngine(
      context: identities[0].context,
      fingerprint: identities[0].fingerprint,
      name: 'test',
      directory: Directory('${root.path}/discovery'),
      allowLoopback: true,
      discoveryPort: port,
    );
    engines.add(instance);
    await instance.start();
    final socket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(socket.close);
    socket.send(
      utf8.encode(
        jsonEncode({
          'protocol': 'vocechat-lan-1',
          'id': identities[1].fingerprint,
          'name': 'Nearby',
          'port': 12345,
        }),
      ),
      InternetAddress.loopbackIPv4,
      port,
    );
    await until(() => instance.peers.isNotEmpty);
    expect(instance.peers.single.name, 'Nearby');
    expect(instance.peers.single.address, InternetAddress.loopbackIPv4);
  });

  for (final fail in [false, true]) {
    test('receive destination callback preserves verified files (fail=$fail)',
        () async {
      final sender = await engine(0);
      final destination = File('${root.path}/custom-${sequence++}.bin');
      final receiver = await engine(1,
          accept: (_) async => true,
          store: (item) async {
            if (fail) throw const FileSystemException('folder unavailable');
            await item.file.rename(destination.path);
            return LanReceivedFile.stored(
                'content://test/custom', item.name, item.size, 'custom');
          });
      final original = await file('route.bin', 1024);
      await sender
          .sendFiles(receiver.selfAt(InternetAddress.loopbackIPv4), [original]);
      expect(sender.phase, LanTransferPhase.completed);
      final received = receiver.received.single;
      if (fail) {
        expect(received.uri, isNull);
        expect(await received.file.readAsBytes(), await original.readAsBytes());
      } else {
        expect(received.uri, 'content://test/custom');
        expect(received.localFile, isNull);
        expect(await destination.readAsBytes(), await original.readAsBytes());
        expect(await receiver.directory.list().toList(), isEmpty);
      }
    });
  }

  test('connection information rejects public addresses and invalid pins', () {
    for (final link in [
      'http://192.168.1.2:1234',
      'vocechat-transfer://8.8.8.8:10?fp=${'a' * 64}',
      'vocechat-transfer://192.168.1.2:1234?fp=bad',
    ]) {
      expect(
        () => LanPeer.parseLink(link),
        throwsA(isA<LanTransferException>()),
      );
    }
  });
}
