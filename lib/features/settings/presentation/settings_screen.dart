import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeOptionProvider);
    final l10n = AppLocale(currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Language Section
          const Text(
            'General Preferences',
            style: TextStyle(
              color: AppColors.secondaryAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primaryAccent),
                  title: Text(l10n.translate('language')),
                  subtitle: Text(currentLocale.languageCode == 'km' ? 'ភាសាខ្មែរ (Khmer)' : 'English'),
                  trailing: DropdownButton<String>(
                    value: currentLocale.languageCode,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.elevatedSurface,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'km', child: Text('ភាសាខ្មែរ')),
                    ],
                    onChanged: (code) {
                      if (code != null) {
                        ref.read(localeProvider.notifier).state =
                            code == 'km' ? AppLocale.kmLocale : AppLocale.enLocale;
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.secondaryAccent),
                  title: Text(l10n.translate('theme')),
                  subtitle: Text(currentTheme == ThemeOption.dark ? 'Dark Charcoal' : 'True AMOLED Black'),
                  trailing: DropdownButton<ThemeOption>(
                    value: currentTheme,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.elevatedSurface,
                    items: const [
                      DropdownMenuItem(value: ThemeOption.dark, child: Text('Dark Charcoal')),
                      DropdownMenuItem(value: ThemeOption.amoled, child: Text('AMOLED Black')),
                    ],
                    onChanged: (theme) {
                      if (theme != null) {
                        ref.read(themeOptionProvider.notifier).state = theme;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Transfers
          const Text(
            'Security & Incoming Transfers',
            style: TextStyle(
              color: AppColors.secondaryAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_protected_setup, color: AppColors.primaryAccent),
                  title: Text(l10n.translate('allowLocalTransfers')),
                  subtitle: const Text('Allow devices on same network to request transfers'),
                  value: true,
                  activeColor: AppColors.primaryAccent,
                  onChanged: (val) {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: AppColors.success),
                  title: const Text('SHA-256 Strict Verification'),
                  subtitle: const Text('Reject any incoming file with hash discrepancy'),
                  trailing: const Icon(Icons.check, color: AppColors.success),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Storage & History
          const Text(
            'Data & Storage',
            style: TextStyle(
              color: AppColors.secondaryAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_shared, color: AppColors.secondaryAccent),
                  title: const Text('Download Folder'),
                  subtitle: const Text('Documents/LinkoraDownloads'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Clear Transfer History'),
                  subtitle: const Text('Does not delete physical files on disk'),
                  onTap: () {
                    ref.read(transferQueueProvider.notifier).clearCompleted();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transfer history cleared.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // About Card
          Center(
            child: Column(
              children: [
                const Text(
                  'LINKORA v1.0.0 (Production Stable)',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Android APK + Windows 10/11 Desktop',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
