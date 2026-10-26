import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../channels/application/conversation_providers.dart';
import '../../contacts/application/user_directory_provider.dart';
import '../data/message_search_filter.dart';

String searchKindLabel(AppL10n l, SearchMessageKind kind) => switch (kind) {
      SearchMessageKind.text => l.filterText,
      SearchMessageKind.all => l.filterAll,
      SearchMessageKind.images => l.filterImages,
      SearchMessageKind.videos => l.filterVideos,
      SearchMessageKind.files => l.filterFiles,
    };

String conversationRouteId(ConversationItem item) => switch (item.key) {
      UserConversationKey(uid: final id) => 'u-$id',
      GroupConversationKey(gid: final id) => 'g-$id',
    };

class MessageSearchFilters extends StatefulWidget {
  const MessageSearchFilters(
      {super.key,
      required this.initial,
      required this.conversations,
      required this.users});
  final MessageSearchFilter initial;
  final List<ConversationItem> conversations;
  final Map<int, UserSummary> users;
  @override
  State<MessageSearchFilters> createState() => _MessageSearchFiltersState();
}

class _MessageSearchFiltersState extends State<MessageSearchFilters> {
  String? _conversation;
  int? _sender;
  DateTimeRange? _dates;
  late SearchMessageKind _kind;
  @override
  void initState() {
    super.initState();
    _conversation = widget.initial.conversationId;
    _sender = widget.initial.senderUid;
    _kind = widget.initial.kind;
    if (widget.initial.from != null && widget.initial.through != null) {
      _dates = DateTimeRange(
          start: widget.initial.from!, end: widget.initial.through!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final targets = {
      for (final item in widget.conversations)
        conversationRouteId(item): item.name
    };
    if (_conversation != null) {
      targets.putIfAbsent(_conversation!, () => _conversation!);
    }
    final senders = {
      for (final user in widget.users.values) user.uid: user.name
    };
    if (_sender != null) {
      senders.putIfAbsent(_sender!, () => l.chatUserFallback(_sender!));
    }
    String date(DateTime value) => '${value.year}/${value.month}/${value.day}';
    return SafeArea(
        child: Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Text(l.searchFilters,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
                key: ValueKey('conversation-$_conversation'),
                initialValue: _conversation,
                hint: Text(l.filterAll),
                isExpanded: true,
                decoration: InputDecoration(labelText: l.filterConversation),
                items: [
                  DropdownMenuItem<String>(
                      value: null, child: Text(l.filterAll)),
                  for (final entry in targets.entries)
                    DropdownMenuItem(
                        value: entry.key,
                        child:
                            Text(entry.value, overflow: TextOverflow.ellipsis))
                ],
                onChanged: (value) => setState(() => _conversation = value)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
                key: ValueKey('sender-$_sender'),
                initialValue: _sender,
                hint: Text(l.filterAll),
                isExpanded: true,
                decoration: InputDecoration(labelText: l.filterSender),
                items: [
                  DropdownMenuItem<int>(value: null, child: Text(l.filterAll)),
                  for (final entry in senders.entries)
                    DropdownMenuItem(
                        value: entry.key,
                        child:
                            Text(entry.value, overflow: TextOverflow.ellipsis))
                ],
                onChanged: (value) => setState(() => _sender = value)),
            const SizedBox(height: 12),
            DropdownButtonFormField<SearchMessageKind>(
                key: ValueKey('kind-$_kind'),
                initialValue: _kind,
                decoration: InputDecoration(labelText: l.filterKind),
                items: [
                  for (final value in SearchMessageKind.values)
                    DropdownMenuItem(
                        value: value, child: Text(searchKindLabel(l, value)))
                ],
                onChanged: (value) => setState(() => _kind = value!)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_dates == null
                    ? '${l.filterDate} · ${l.filterNoDates}'
                    : '${date(_dates!.start)} – ${date(_dates!.end)}'),
                onPressed: () async {
                  final value = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: _dates);
                  if (mounted && value != null) setState(() => _dates = value);
                }),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(
                  onPressed: () => setState(() {
                        _conversation = null;
                        _sender = null;
                        _dates = null;
                        _kind = SearchMessageKind.text;
                      }),
                  child: Text(l.filterReset)),
              FilledButton(
                  onPressed: () => Navigator.pop(
                      context,
                      MessageSearchFilter(
                          conversationId: _conversation,
                          senderUid: _sender,
                          from: _dates?.start,
                          through: _dates?.end,
                          kind: _kind)),
                  child: Text(l.filterApply)),
            ]),
          ])),
    ));
  }
}
