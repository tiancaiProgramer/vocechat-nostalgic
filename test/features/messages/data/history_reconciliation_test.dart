import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/features/messages/domain/history_reconciliation.dart';
import 'package:vocechat_client/features/messages/domain/message_models.dart';

ChatMessage _message(int mid) => ChatMessage(
      mid: mid,
      fromUid: 2,
      createdAt: 1000,
      target: const MessageTarget.group(gid: 42),
      detail: const MessageDetail.normal(
        contentType: 'text/plain',
        content: 'text',
      ),
    );

void main() {
  test('parses the admin clear broadcast and rejects malformed boundaries', () {
    expect(
      parseSseEvent(
        'message_cleared',
        '{"type":"message_cleared","latest_deleted_mid":100}',
      ),
      const ChatEvent.messagesCleared(latestDeletedMid: 100),
    );
    for (final raw in [
      '{}',
      '{"latest_deleted_mid":-1}',
      '{"latest_deleted_mid":"100"}',
    ]) {
      expect(parseSseEvent('message_cleared', raw), isA<ChatEventUnknown>());
    }
  });

  test('a replayed server clear command is never displayed as empty text', () {
    expect(
      parseSseEvent(
        'chat',
        '{"type":"chat","mid":101,"from_uid":1,"created_at":1000,'
            '"target":{"uid":-1},"detail":{"type":"command"}}',
      ),
      const ChatEvent.messagesCleared(latestDeletedMid: 101),
    );
  });

  test('a full page cannot delete history outside its covered interval', () {
    expect(
      missingHistoryMids(
        [
          for (final mid in [-1, 19, 20, 21, 22, 23, 24]) _message(mid),
        ],
        [_message(23), _message(21)],
        limit: 2,
        throughMid: 23,
      ),
      {22},
    );
    expect(
      missingHistoryMids(
        [
          for (final mid in [19, 20, 21, 22, 23, 24]) _message(mid),
        ],
        [_message(20), _message(19)],
        limit: 3,
        throughMid: 24,
        beforeMid: 22,
      ),
      {21},
    );
  });
}
