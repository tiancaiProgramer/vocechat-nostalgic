// Manual, opt-in device test. Run with VC_LAN_TEST_DIR and VC_LAN_TEST_PHONE.
// Uses only a generated fixture; never accepts arbitrary user files.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/local_transfer/data/lan_transfer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('manual phone LAN transfer', () async {
    final path = Platform.environment['VC_LAN_TEST_DIR'];
    final phone = Platform.environment['VC_LAN_TEST_PHONE'];
    if (path == null || phone == null) {
      fail('Set VC_LAN_TEST_DIR and VC_LAN_TEST_PHONE explicitly.');
    }
    HttpOverrides.global = null;
    final root = Directory(path);
    await root.create(recursive: true);
    final keys = await Directory.systemTemp.createTemp('vc-device-peer-');
    LanTransferEngine? engine;
    try {
      final cert = '${keys.path}/cert.pem', key = '${keys.path}/key.pem';
      final created = await Process.run('/usr/bin/openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-keyout',
        key,
        '-out',
        cert,
        '-days',
        '1',
        '-subj',
        '/CN=VoceChat Device Test'
      ]);
      expect(created.exitCode, 0, reason: 'Ephemeral test identity');
      final fixture = File('${root.path}/VoceChat-transfer-test-150MB.bin');
      final writer = await fixture.open(mode: FileMode.write);
      await writer.truncate(150 * 1024 * 1024 + 17);
      await writer.setPosition(150 * 1024 * 1024);
      await writer.writeFrom(List.generate(17, (i) => i + 1));
      await writer.close();
      final expectedHash = await sha256.bind(fixture.openRead()).first;
      final context = SecurityContext(withTrustedRoots: false)
        ..useCertificateChain(cert)
        ..usePrivateKey(key);
      final activeEngine = engine = LanTransferEngine(
          context: context,
          fingerprint: LanTransferEngine.certificateFingerprint(
              await File(cert).readAsString()),
          name: 'Codex 测试设备',
          directory: Directory('${root.path}/received'),
          broadcasts: [
            InternetAddress(Platform.environment['VC_LAN_TEST_BROADCAST'] ??
                '255.255.255.255')
          ],
          onIncoming: (offer) async {
            final valid = offer.files.length == 1 &&
                offer.files.single.size == await fixture.length() &&
                offer.files.single.hash == expectedHash.toString();
            stdout.writeln(
                'DEVICE_TEST incoming expected_fixture=$valid code=${offer.verificationCode}');
            return valid;
          });
      await activeEngine.start();
      var lastPeers = '', lastPhase = LanTransferPhase.idle;
      var checkedReceived = 0;
      activeEngine.addListener(() {
        final peers = activeEngine.peers
            .where((p) => p.address.address == phone)
            .toList();
        final value = peers.map((p) => p.fingerprint).join();
        if (lastPeers != value) {
          lastPeers = value;
          stdout.writeln('DEVICE_TEST phone_discovered=${peers.isNotEmpty}');
        }
        if (lastPhase != activeEngine.phase) {
          lastPhase = activeEngine.phase;
          stdout.writeln(
              'DEVICE_TEST phase=${lastPhase.name} error=${activeEngine.errorCode ?? "none"} code=${activeEngine.verificationCode ?? "none"}');
        }
      });
      await File('${root.path}/ready').writeAsString('ready');
      stdout.writeln('DEVICE_TEST ready');
      final end = DateTime.now().add(const Duration(minutes: 25));
      while (DateTime.now().isBefore(end)) {
        final command = File('${root.path}/command');
        if (await command.exists()) {
          final action = (await command.readAsString()).trim();
          await command.delete();
          if (action == 'stop') break;
          if (action == 'send' && !activeEngine.busy) {
            final peer = activeEngine.peers
                .where((p) => p.address.address == phone)
                .firstOrNull;
            if (peer == null) {
              stdout.writeln('DEVICE_TEST cannot_send_phone_not_discovered');
            } else {
              unawaited(activeEngine.sendFiles(peer, [fixture]));
            }
          }
          if (action == 'cancel') await activeEngine.cancel();
        }
        if (!activeEngine.busy &&
            activeEngine.received.length > checkedReceived) {
          for (final item in activeEngine.received.skip(checkedReceived)) {
            final actual = await sha256.bind(item.file.openRead()).first;
            stdout.writeln(
                'DEVICE_TEST phone_to_mac bytes=${item.size} hash_match=${actual == expectedHash}');
            expect(actual, expectedHash);
          }
          checkedReceived = activeEngine.received.length;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } finally {
      engine?.dispose();
      await keys.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 28)));
}
