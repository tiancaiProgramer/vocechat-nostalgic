import '../../messages/domain/message_models.dart';

enum SearchMessageKind { text, all, images, videos, files }

class MessageSearchFilter {
  const MessageSearchFilter(
      {this.conversationId,
      this.senderUid,
      this.from,
      this.through,
      this.kind = SearchMessageKind.text});
  final String? conversationId;
  final int? senderUid;
  final DateTime? from, through;
  final SearchMessageKind kind;
  bool get isActive =>
      conversationId != null ||
      senderUid != null ||
      from != null ||
      through != null ||
      kind != SearchMessageKind.text;

  bool includes(String conversation, ChatMessage message) {
    if (conversationId != null && conversationId != conversation) return false;
    if (senderUid != null && senderUid != message.fromUid) return false;
    if (from != null &&
        message.createdAt <
            DateTime(from!.year, from!.month, from!.day)
                .millisecondsSinceEpoch) {
      return false;
    }
    if (through != null &&
        message.createdAt >=
            DateTime(through!.year, through!.month, through!.day + 1)
                .millisecondsSinceEpoch) {
      return false;
    }
    final actual = messageKind(message);
    return kind == SearchMessageKind.all || actual == kind;
  }
}

Map<String, dynamic> messageProperties(ChatMessage message) =>
    switch (message.detail) {
      NormalMessageDetail(:final properties) => properties ?? const {},
      ReplyMessageDetail(:final properties) => properties ?? const {},
      _ => const {},
    };

SearchMessageKind? messageKind(ChatMessage message) {
  final type = message.displayContentType.toLowerCase();
  if (type == 'text/plain' || type == 'text/markdown') {
    return SearchMessageKind.text;
  }
  final declared = messageProperties(message)['content_type'];
  final mime = declared is String && declared.trim().isNotEmpty
      ? declared.trim().toLowerCase()
      : type;
  if (mime.startsWith('image/')) return SearchMessageKind.images;
  if (mime.startsWith('video/')) return SearchMessageKind.videos;
  if (type == 'vocechat/file' ||
      type == 'vocechat/audio' ||
      mime.startsWith('audio/')) {
    return SearchMessageKind.files;
  }
  return null;
}

String messageSearchText(ChatMessage message) {
  if (messageKind(message) == SearchMessageKind.text) {
    return message.displayContent;
  }
  final name = messageProperties(message)['name'];
  return name is String ? name : '';
}
