import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../legacy_ui/legacy_chrome.dart';

class SearchPage extends StatelessWidget {
  const SearchPage(
      {super.key,
      required this.title,
      required this.hint,
      required this.controller,
      required this.onChanged,
      required this.child});
  final String title, hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTokens.surface,
        body: SafeArea(
            child: Column(children: [
          LegacyTitleBar(
              title: title,
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                child: Icon(CupertinoIcons.back, color: AppTokens.gray700),
              )),
          LegacySearchField(
              controller: controller,
              onChanged: onChanged,
              hint: hint,
              autofocus: true),
          Expanded(child: child),
        ])),
      );
}
