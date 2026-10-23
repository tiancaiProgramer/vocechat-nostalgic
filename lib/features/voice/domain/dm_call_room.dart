import '../../messages/domain/message_models.dart';
import 'voice_models.dart';

class DmCallRoom {
  const DmCallRoom({required this.ownerUid, required this.channelName});
  final int ownerUid;
  final String channelName;
}

/// The DM peer identifies the chat; the callee identifies the RTC room.
/// Resolve existing membership before every entry point, including the header.
Future<DmCallRoom?> resolveDmCallRoom({
  required int selfUid,
  required int peerUid,
  required List<ActiveVoiceChannel> channels,
  required Future<List<int>> Function(String) loadUsers,
}) async {
  final matches = <DmCallRoom>[];
  for (final channel in channels) {
    final target = channel.context;
    if (target is! MessageTargetUser || channel.userCount < 1) continue;
    if (target.uid != selfUid && target.uid != peerUid) continue;
    final users = await loadUsers(channel.channelName);
    if (!users.contains(peerUid) ||
        users.any((uid) => uid != selfUid && uid != peerUid)) continue;
    matches.add(
      DmCallRoom(ownerUid: target.uid, channelName: channel.channelName),
    );
  }
  if (matches.length > 1) throw StateError('双方同时发起了通话，请挂断后由一方重新发起');
  return matches.isEmpty ? null : matches.single;
}
