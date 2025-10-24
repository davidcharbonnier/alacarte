import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locale_provider.dart';
import '../../utils/localization_utils.dart';

/// Enhanced language selector with Auto/French/English options
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPreference = ref.watch(localePreferenceProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Auto option
        _LanguageRadioOption(
          title: _getAutoOptionTitle(context, ref),
          subtitle: context.l10n.followsDeviceLanguage,
          value: LocalePreference.auto,
          groupValue: currentPreference,
          onChanged: (value) => ref.read(localePreferenceProvider.notifier).setPreference(value!),
        ),
        
        // French option
        _LanguageRadioOption(
          title: context.l10n.french,
          subtitle: null,
          value: LocalePreference.french,
          groupValue: currentPreference,
          onChanged: (value) => ref.read(localePreferenceProvider.notifier).setPreference(value!),
        ),
        
        // English option
        _LanguageRadioOption(
          title: context.l10n.english,
          subtitle: null,
          value: LocalePreference.english,
          groupValue: currentPreference,
          onChanged: (value) => ref.read(localePreferenceProvider.notifier).setPreference(value!),
        ),
      ],
    );
  }
  
  String _getAutoOptionTitle(BuildContext context, WidgetRef ref) {
    final deviceLocale = ref.read(localePreferenceProvider.notifier).getDeviceLocale();
    final detectedLanguage = deviceLocale.languageCode == 'fr' 
        ? context.l10n.french 
        : context.l10n.english;
    return context.l10n.automaticLanguage(detectedLanguage);
  }
}

class _LanguageRadioOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final LocalePreference value;
  final LocalePreference groupValue;
  final ValueChanged<LocalePreference?> onChanged;

  const _LanguageRadioOption({
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return RadioListTile<LocalePreference>(
      // Ignore deprecated parameters - still the recommended approach until RadioGroup is available
      // ignore: deprecated_member_use
      value: value,
      // ignore: deprecated_member_use  
      groupValue: groupValue,
      // ignore: deprecated_member_use
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ) : null,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
