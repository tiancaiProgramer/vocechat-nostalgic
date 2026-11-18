import 'message_models.dart';

/// Confirmed rows absent from a successful server history page. A short page
/// covers all older history; a full page only covers mids from its oldest row.
/// The request's local boundary protects messages delivered while HTTP waited.
Set<int> missingHistoryMids(
  List<ChatMessage> cached,
  List<ChatMessage> history, {
  required int limit,
  required int throughMid,
  int? beforeMid,
}) {
  final present = history.map((m) => m.mid).toSet();
  final positiveMids = present.where((mid) => mid > 0);
  final oldest =
      positiveMids.isEmpty ? 0 : positiveMids.reduce((a, b) => a < b ? a : b);
  return {
    for (final m in cached)
      if (m.mid > 0 &&
          m.mid <= throughMid &&
          (beforeMid == null || m.mid < beforeMid) &&
          (history.length < limit || m.mid >= oldest) &&
          !present.contains(m.mid))
        m.mid,
  };
}
