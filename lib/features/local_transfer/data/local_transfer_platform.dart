import 'dart:io';
import 'dart:convert';
import 'lan_transfer.dart';
import 'package:flutter/services.dart';

const localTransferChannel = MethodChannel('chat.voce/local_transfer');

class LocalTransferIdentity {
  const LocalTransferIdentity(this.context, this.fingerprint, this.name,
      this.addresses, this.broadcasts);
  final SecurityContext context;
  final String fingerprint, name;
  final List<InternetAddress> addresses, broadcasts;
}

Future<LocalTransferIdentity> prepareLocalTransfer() async {
  final data =
      await localTransferChannel.invokeMapMethod<String, dynamic>('prepare');
  if (data == null) throw const LanTransferException('network');
  final certificate = data['certificate'] as String;
  final context = SecurityContext(withTrustedRoots: false)
    ..useCertificateChainBytes(utf8.encode(certificate))
    ..usePrivateKeyBytes(utf8.encode(data['privateKey'] as String));
  List<InternetAddress> addresses(String field) =>
      (data[field] as List? ?? const [])
          .whereType<String>()
          .map(InternetAddress.tryParse)
          .whereType<InternetAddress>()
          .toList();
  return LocalTransferIdentity(
      context,
      LanTransferEngine.certificateFingerprint(certificate),
      data['name'] as String,
      addresses('addresses'),
      addresses('broadcasts'));
}
