import 'dart:io';
import 'lan_transfer.dart';

/// Acknowledged files leave the queue; failed/cancelled files remain retryable.
class OutgoingTransferQueue {
  final files = <File>[];

  Future<void> send(LanTransferEngine engine, LanPeer peer) async {
    if (engine.busy || files.isEmpty) return;
    final batch = List<File>.of(files);
    await engine.sendFiles(peer, batch);
    final delivered = engine.completedOutgoingPaths.intersection(
      batch.map((file) => file.path).toSet(),
    );
    files.removeWhere((file) => delivered.contains(file.path));
  }
}
