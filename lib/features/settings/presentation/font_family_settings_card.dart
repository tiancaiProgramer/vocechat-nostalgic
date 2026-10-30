import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/font_family_provider.dart';
import '../../../core/theme/system_font_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class FontFamilySettingsCard extends ConsumerWidget {
  const FontFamilySettingsCard({super.key});

  Future<void> _select(
      BuildContext context, WidgetRef ref, AppFontFamily value) async {
    try {
      await ref.read(fontFamilyProvider.notifier).select(value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).appearanceFontFamilySaveFailed),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final colors = Theme.of(context).colorScheme;
    final selected = ref.watch(fontFamilyProvider);
    return Container(
      constraints: const BoxConstraints(maxWidth: 512),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.appearanceFontFamily,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface)),
          const SizedBox(height: 8),
          if (selected == AppFontFamily.system &&
              ref.watch(systemFontProvider).failed)
            Text(l.appearanceSystemFontUnavailable,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          RadioGroup<AppFontFamily>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) _select(context, ref, value);
            },
            child: Column(children: [
              for (final value in AppFontFamily.values)
                RadioListTile<AppFontFamily>(
                  key: ValueKey('font-family-${value.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: value,
                  title: Text(
                    value == AppFontFamily.system
                        ? l.appearanceFontFamilySystem
                        : l.appearanceFontFamilyBundled,
                    style: TextStyle(fontSize: 14, color: colors.onSurface),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
