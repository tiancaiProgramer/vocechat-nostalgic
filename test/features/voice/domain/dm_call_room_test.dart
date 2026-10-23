import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/voice/domain/dm_call_room.dart';
import 'package:vocechat_client/features/voice/domain/voice_models.dart';

void main() {
  ActiveVoiceChannel dm(int owner) => ActiveVoiceChannel.fromJson(
      {'channel_name': 'vocechat:dm:$owner', 'user_count': 1});
  for (final self in [7, 42]) {
    final peer = self == 7 ? 42 : 7;
    test('header entry by callee $self reuses incoming room', () async {
      final room = await resolveDmCallRoom(
          selfUid: self,
          peerUid: peer,
          channels: [dm(self)],
          loadUsers: (_) async => [peer]);
      expect(room?.ownerUid, self);
      expect(room?.channelName, 'vocechat:dm:$self');
    });
    test('rejoining by caller $self reuses outgoing room', () async {
      final room = await resolveDmCallRoom(
          selfUid: self,
          peerUid: peer,
          channels: [dm(peer)],
          loadUsers: (_) async => [peer]);
      expect(room?.ownerUid, peer);
    });
  }
  test('unrelated incoming caller cannot hijack the selected chat', () async {
    expect(
        await resolveDmCallRoom(
            selfUid: 7,
            peerUid: 42,
            channels: [dm(7), dm(99)],
            loadUsers: (_) async => [99]),
        isNull);
  });
  test('an empty or unrelated group room is ignored', () async {
    expect(
        await resolveDmCallRoom(
            selfUid: 7,
            peerUid: 42,
            channels: [
              ActiveVoiceChannel.fromJson(
                  {'channel_name': 'vocechat:group:7', 'user_count': 1}),
              dm(7)
            ],
            loadUsers: (_) async => []),
        isNull);
  });
  test('simultaneous opposite invitations ask for a single fresh call',
      () async {
    await expectLater(
        resolveDmCallRoom(
            selfUid: 7,
            peerUid: 42,
            channels: [dm(7), dm(42)],
            loadUsers: (_) async => [42]),
        throwsStateError);
  });
}
