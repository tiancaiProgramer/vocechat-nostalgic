import 'package:flutter/foundation.dart';
import '../features/channels/application/conversation_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/server_store.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/account_switcher_sheet.dart';
import '../features/contacts/application/user_directory_provider.dart';
import '../features/channels/presentation/create_channel_dialog.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/voce_avatar.dart';
import 'legacy_icons.dart';
import '../core/background/background_preferences.dart';

bool get usesLegacyPhoneLayout =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class LegacyTitleBar extends StatelessWidget {
  const LegacyTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.centerTitle = true,
  });
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final bool centerTitle;
  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(color: AppTokens.borderSubtle, width: .5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 56, child: leading),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.gray700,
                    ),
                  ),
                  if (subtitle?.isNotEmpty == true)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppTokens.zinc500),
                    ),
                ],
              ),
            ),
            SizedBox(width: 56, child: trailing),
          ],
        ),
      );
}

class LegacySearchField extends StatelessWidget {
  const LegacySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hint,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).appBarTheme.backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: CupertinoSearchTextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          placeholder: hint,
          style: TextStyle(fontSize: 16, color: AppTokens.gray700),
          backgroundColor: AppTokens.gray200.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class LegacyServerHeader extends ConsumerWidget {
  const LegacyServerHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serverStoreProvider).valueOrNull;
    final server =
        state?.servers.where((s) => s.id == state.currentServerId).firstOrNull;
    final count = ref.watch(userDirectoryProvider).valueOrNull?.length;
    final l = AppL10n.of(context);
    return LegacyTitleBar(
      title: server?.name ?? 'VoceChat',
      centerTitle: false,
      subtitle: count == null ? null : '$count ${l.navContacts}',
      leading: CupertinoButton(
        padding: const EdgeInsets.all(10),
        onPressed: () => Scaffold.of(context).openDrawer(),
        child: VoceAvatar(
          name: server?.name ?? 'V',
          size: 32,
          imageUrl: server == null
              ? null
              : '${server.baseUrl}/api/resource/organization/logo',
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(AppIcons.add, size: 24, color: AppTokens.zinc500),
        onSelected: (value) {
          if (value == 'transfer') {
            context.push('/file-transfer');
          } else if (value == 'search') {
            context.push('/home/search');
          } else if (value == 'group') {
            showCreateChannelDialog(context);
          } else {
            context.push('/home/people');
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'group', child: Text(l.chatListNewChat)),
          PopupMenuItem(value: 'dm', child: Text(l.navContacts)),
          PopupMenuItem(value: 'search', child: Text(l.actionSearch)),
          if (isAndroidBackgroundSupported)
            PopupMenuItem(value: 'transfer', child: Text(l.localTransferTitle)),
        ],
      ),
    );
  }
}

class LegacyServerDrawer extends ConsumerWidget {
  const LegacyServerDrawer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final state = ref.watch(serverStoreProvider).valueOrNull;
    Widget section(String id, String title, Widget content) => Container(
          key: ValueKey('drawer-$id-card'),
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: Border.all(color: AppTokens.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.gray600))),
            content,
          ]),
        );
    return Drawer(
      backgroundColor: AppTokens.canvas,
      child: SafeArea(
          child: Column(children: [
        LegacyTitleBar(
          title: 'VoceChat',
          leading: PopupMenuButton<String>(
            key: const ValueKey('drawer-add'),
            tooltip: l.accountSwitcherAdd,
            icon: const Icon(Icons.add),
            onSelected: (action) {
              Navigator.pop(context);
              if (action == 'transfer') {
                context.push('/file-transfer');
              } else if (action == 'account') {
                showAddAccountScreen(context);
              } else {
                context.push('/server-picker?add=1');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'account', child: Text(l.accountSwitcherAddAccount)),
              PopupMenuItem(value: 'server', child: Text(l.serverPickerAdd)),
              if (isAndroidBackgroundSupported)
                PopupMenuItem(
                    value: 'transfer', child: Text(l.localTransferTitle)),
            ],
          ),
        ),
        Expanded(
            child:
                ListView(padding: const EdgeInsets.only(bottom: 12), children: [
          section('accounts', l.accountSwitcherTitle,
              const AccountSwitcherList(showAddAccount: false)),
          section(
              'servers',
              l.accountSwitcherServersTitle,
              Column(children: [
                for (var i = 0; i < (state?.servers.length ?? 0); i++) ...[
                  if (i > 0) const Divider(height: .5, indent: 16),
                  ListTile(
                    leading: VoceAvatar(
                        name: state!.servers[i].name,
                        size: 40,
                        imageUrl:
                            '${state.servers[i].baseUrl}/api/resource/organization/logo'),
                    title: Text(state.servers[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 16, color: AppTokens.gray700)),
                    subtitle: Text(state.servers[i].baseUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: AppTokens.gray500)),
                    trailing: state.servers[i].id == state.currentServerId
                        ? Icon(Icons.check, color: AppTokens.primary400)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/server-picker');
                    },
                  ),
                ],
              ])),
        ])),
      ])),
    );
  }
}

class LegacyUnreadIcon extends ConsumerWidget {
  const LegacyUnreadIcon({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
    var count = 0;
    for (final conversation in conversations) {
      count +=
          ref.watch(unreadInfoProvider(conversation.key)).valueOrNull?.count ??
              0;
    }
    return Stack(clipBehavior: Clip.none, children: [
      const Padding(
          padding: EdgeInsets.only(top: 8, left: 4, right: 4),
          child: Icon(AppIcons.chat, size: 30)),
      if (count > 0)
        Positioned(
            top: 2,
            right: -6,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                decoration: BoxDecoration(
                    color: AppTokens.primary400,
                    borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Text(count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)))),
    ]);
  }
}

class LegacyBottomBar extends StatelessWidget {
  const LegacyBottomBar(
      {super.key, required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => CupertinoTabBar(
        height: 60,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        activeColor: AppTokens.gray800,
        inactiveColor: const Color(0xFF9E9E9E),
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: const LegacyUnreadIcon(),
            label: AppL10n.of(context).navChats,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(AppIcons.contact, size: 30),
            ),
            label: AppL10n.of(context).navContacts,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(AppIcons.setting, size: 30),
            ),
            label: AppL10n.of(context).navSettings,
          ),
        ],
      );
}
