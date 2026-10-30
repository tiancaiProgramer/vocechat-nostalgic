import 'dart:io';
import 'dart:convert';
import 'lan_transfer.dart';
import 'package:flutter/services.dart';

const localTransferChannel = MethodChannel('chat.voce/local_transfer');
const receivedFileExportChannel =
    MethodChannel('chat.voce/received_file_export');

Future<bool> saveReceivedFileAs(LanReceivedFile file, String scope) async =>
    await receivedFileExportChannel.invokeMethod<bool>(
      'save',
      {'path': file.localFile?.path, 'uri': file.uri, 'scope': scope},
    ) ??
    false;

class ReceiveLocations {
  const ReceiveLocations(this.images, this.files, this.received);
  factory ReceiveLocations.fromMap(Map<dynamic, dynamic> map) =>
      ReceiveLocations(
        (map['images'] as Map?)?['label'] as String?,
        (map['files'] as Map?)?['label'] as String?,
        (map['received'] as List? ?? [])
            .map((value) => storedReceivedFile(value as Map))
            .toList(),
      );
  final String? images, files;
  final List<LanReceivedFile> received;
}

LanReceivedFile storedReceivedFile(Map<dynamic, dynamic> value) =>
    LanReceivedFile.stored(value['uri'] as String, value['name'] as String,
        (value['size'] as num).toInt(), value['location'] as String);

Future<ReceiveLocations> receiveLocations(String scope) async =>
    ReceiveLocations.fromMap(
      await receivedFileExportChannel
              .invokeMapMethod('locations', {'scope': scope}) ??
          {},
    );

Future<ReceiveLocations?> chooseReceiveLocation(String scope, String kind,
    {bool reset = false}) async {
  final value = await receivedFileExportChannel.invokeMapMethod(
    reset ? 'resetLocation' : 'chooseLocation',
    {'scope': scope, 'kind': kind},
  );
  return value == null ? null : ReceiveLocations.fromMap(value);
}

Future<LanReceivedFile> storeReceivedFile(
    LanReceivedFile item, String scope) async {
  final value = await receivedFileExportChannel
      .invokeMapMethod('store', {'scope': scope, 'path': item.file.path});
  return value == null ? item : storedReceivedFile(value);
}

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
