import '../../../legacy_ui/legacy_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/server_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/safe_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/loading_capsule.dart';
import '../../../shared/widgets/voce_avatar.dart';
import '../../channels/application/pending_chat_selection.dart';
import '../../profile/presentation/user_profile_card.dart';
import '../application/contacts_provider.dart';
import '../application/presence_provider.dart';
import '../application/user_directory_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _selectedUid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = !usesLegacyPhoneLayout && constraints.maxWidth >= 700;
        final l = AppL10n.of(context);
        final asyncContacts = ref.watch(contactsProvider);

        Widget listPanel = Container(
          width: isWide ? 268 : double.infinity,
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: isWide
                ? Border(right: BorderSide(color: AppTokens.gray200, width: 1))
                : null,
          ),
          child: Column(
            children: [
              _ContactsHeader(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: asyncContacts.when(
                  loading: () =>
                      Center(child: LoadingCapsule(label: l.contactsLoading)),
                  error: (e, _) => Center(
                    child: Text(safeText(l.errorPrefix(e.toString()))),
                  ),
                  data: (allContacts) {
                    final q = _query.toLowerCase();
                    final filtered = q.isEmpty
                        ? allContacts
                        : allContacts
                            .where(
                              (c) =>
                                  c.name.toLowerCase().contains(q) ||
                                  c.email.toLowerCase().contains(q),
                            )
                            .toList();

                    // Heuristic: if email contains "bot" treat as bot section.
                    // Otherwise, contacts. Mirrors Figma's BOT / CONTACT split.
                    final bots = filtered
                        .where(
                          (c) =>
                              c.email.toLowerCase().contains('bot') ||
                              c.name.toLowerCase().contains('bot'),
                        )
                        .toList();
                    final contacts =
                        filtered.where((c) => !bots.contains(c)).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          l.contactsEmpty,
                          style: TextStyle(
                            color: AppTokens.gray500,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      children: [
                        if (bots.isNotEmpty) ...[
                          _SectionLabel(l.contactsSectionBot(bots.length)),
                          ...bots.map(
                            (c) => _ContactTile(
                              contact: c,
                              isBot: true,
                              isSelected: isWide && _selectedUid == c.uid,
                              onTap: () => _onContactTap(context, c, isWide),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (contacts.isNotEmpty) ...[
                          _SectionLabel(
                            l.contactsSectionContact(contacts.length),
                          ),
                          ...contacts.map(
                            (c) => _ContactTile(
                              contact: c,
                              isBot: false,
                              isSelected: isWide && _selectedUid == c.uid,
                              onTap: () => _onContactTap(context, c, isWide),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );

        if (!isWide) {
          return listPanel;
        }

        // Wide: side-by-side panel with profile/empty placeholder.
        final selectedContact = asyncContacts.valueOrNull
            ?.where((c) => c.uid == _selectedUid)
            .firstOrNull;
        return Row(
          children: [
            listPanel,
            Expanded(
              child: selectedContact != null
                  ? _ContactProfile(contact: selectedContact)
                  : const _ContactsEmptyState(),
            ),
          ],
        );
      },
    );
  }

  void _onContactTap(BuildContext context, ContactInfo c, bool isWide) {
    if (isWide) {
      setState(() => _selectedUid = c.uid);
    } else {
      context.go('/home/chat/u-${c.uid}');
    }
  }
}

// ---------------------------------------------------------------------------
// _ContactsHeader — pill search + add button.
// ---------------------------------------------------------------------------

class _ContactsHeader extends StatelessWidget {
  const _ContactsHeader({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          LegacyTitleBar(title: AppL10n.of(context).navContacts),
          LegacySearchField(
            controller: controller,
            onChanged: onChanged,
            hint: AppL10n.of(context).contactsSearch,
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// _SectionLabel — uppercase BOT - 3 / CONTACT - 47 label rows.
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTokens.gray500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ContactTile — Figma "Contacts / Item" with 32px avatar.
// Bots show a robot indicator overlay; people show a green status dot.
// ---------------------------------------------------------------------------

class _ContactTile extends ConsumerWidget {
  const _ContactTile({
    required this.contact,
    required this.isBot,
    required this.isSelected,
    required this.onTap,
  });

  final ContactInfo contact;
  final bool isBot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isSelected ? AppTokens.selected : Colors.transparent;

    // Resolve the avatar URL from the user directory + active server.
    final userDir = ref.watch(userDirectoryProvider).valueOrNull ?? const {};
    final serverState = ref.watch(serverStoreProvider).valueOrNull;
    final baseUrl = serverState?.servers
            .where((s) => s.id == serverState.currentServerId)
            .firstOrNull
            ?.baseUrl ??
        '';
    String? avatarUrl;
    final u = userDir[contact.uid];
    if (u != null && (u.avatarUpdatedAt ?? 0) > 0 && baseUrl.isNotEmpty) {
      avatarUrl =
          '$baseUrl/api/resource/avatar?uid=${contact.uid}&t=${u.avatarUpdatedAt}';
    }

    final showStatus = ref.watch(showOnlineStatusProvider);
    final presence = ref.watch(presenceForDisplayProvider);
    final isOnline = presence[contact.uid] ?? false;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppTokens.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showUserProfileOverlay(context, uid: contact.uid),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      VoceAvatar(
                        name: safeText(contact.name),
                        imageUrl: avatarUrl,
                        size: 40,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: isBot
                            ? Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTokens.gray100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTokens.surface,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  size: 8,
                                  color: AppTokens.gray600,
                                ),
                              )
                            : showStatus
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? AppTokens.successDot
                                          : AppTokens.gray400,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTokens.surface,
                                        width: 2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  safeText(contact.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTokens.gray600 : AppTokens.gray700,
                    height: 20 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ContactProfile — right-pane profile preview (mirrors Figma "Profile" card).
// ---------------------------------------------------------------------------

class _ContactProfile extends ConsumerWidget {
  const _ContactProfile({required this.contact});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final userDir = ref.watch(userDirectoryProvider).valueOrNull ?? const {};
    final serverState = ref.watch(serverStoreProvider).valueOrNull;
    final baseUrl = serverState?.servers
            .where((s) => s.id == serverState.currentServerId)
            .firstOrNull
            ?.baseUrl ??
        '';
    String? avatarUrl;
    final u = userDir[contact.uid];
    if (u != null && (u.avatarUpdatedAt ?? 0) > 0 && baseUrl.isNotEmpty) {
      avatarUrl =
          '$baseUrl/api/resource/avatar?uid=${contact.uid}&t=${u.avatarUpdatedAt}';
    }

    return Container(
      color: AppTokens.surface,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoceAvatar(
              name: safeText(contact.name),
              imageUrl: avatarUrl,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              safeText(contact.name),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTokens.gray800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${safeText(contact.email).split('@').first}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: AppTokens.gray400,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 24),
            // Flexible actions: each caps at 128px but shrinks near the
            // 700px two-pane breakpoint instead of overflowing the pane.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _ProfileAction(
                    icon: Icons.chat_bubble_outline,
                    label: l.contactsMessage,
                    isPrimary: true,
                    onTap: () {
                      final width = MediaQuery.sizeOf(context).width;
                      final isWide = !usesLegacyPhoneLayout && width >= 700;
                      if (isWide) {
                        // Tell the chat list which conversation to select, then
                        // switch to the home tab — the list's didChangeDependencies
                        // picks up the request and renders the two-pane view.
                        ref
                            .read(pendingChatSelectionProvider.notifier)
                            .request('u-${contact.uid}');
                        context.go('/home');
                      } else {
                        context.go('/home/chat/u-${contact.uid}');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _ProfileAction(
                    icon: Icons.call_outlined,
                    label: l.contactsCall,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _ProfileAction(
                    icon: Icons.more_horiz,
                    label: l.actionMore,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppL10n.of(context).comingSoon),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: AppTokens.hover,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 128, minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppTokens.gray50 : AppTokens.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTokens.gray500),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTokens.gray500,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsEmptyState extends StatelessWidget {
  const _ContactsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      color: AppTokens.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 30,
              color: AppTokens.primary500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.contactsSelectTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTokens.gray700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.contactsSelectSubtitle,
            style: TextStyle(fontSize: 13, color: AppTokens.gray500),
          ),
        ],
      ),
    );
  }
}
