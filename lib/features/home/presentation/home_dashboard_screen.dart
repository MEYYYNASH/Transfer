import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);
    final activeTransfers = ref.watch(transferQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
              ),
              child: const Icon(Icons.bolt, color: AppColors.primaryAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.translate('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: AppColors.secondaryAccent),
            tooltip: l10n.translate('securitySettings'),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.system_update_alt, color: AppColors.mainText),
            tooltip: l10n.translate('checkForUpdates'),
            onPressed: () => context.push('/updates'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Status Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1738), Color(0xFF171A23)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'P2P Engine Active',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.wifi_tethering, color: AppColors.secondaryAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('appTagline'),
                    style: const TextStyle(
                      color: AppColors.mainText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Direct Wi-Fi LAN sockets, end-to-end SHA-256 verification, and encrypted Cloud Sharing.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Grid
            const Text(
              'Actions',
              style: TextStyle(
                color: AppColors.mainText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                _buildActionCard(
                  context,
                  title: l10n.translate('sendFiles'),
                  subtitle: 'Wi-Fi / Nearby',
                  icon: Icons.upload_file,
                  color: AppColors.primaryAccent,
                  route: '/send',
                ),
                _buildActionCard(
                  context,
                  title: l10n.translate('receiveFiles'),
                  subtitle: 'Hotspot / QR Code',
                  icon: Icons.download_for_offline,
                  color: AppColors.secondaryAccent,
                  route: '/receive',
                ),
                _buildActionCard(
                  context,
                  title: l10n.translate('cloudUpload'),
                  subtitle: 'Upload & Generate Link',
                  icon: Icons.cloud_upload_outlined,
                  color: const Color(0xFF6366F1),
                  route: '/cloud-share',
                ),
                _buildActionCard(
                  context,
                  title: l10n.translate('pasteToDownload'),
                  subtitle: 'Safe File Preview',
                  icon: Icons.link,
                  color: const Color(0xFFEAB308),
                  route: '/paste-download',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Active Transfers Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('activeTransfers'),
                  style: const TextStyle(
                    color: AppColors.mainText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/transfers'),
                  child: const Text('View All', style: TextStyle(color: AppColors.primaryAccent)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (activeTransfers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.swap_horiz, size: 40, color: AppColors.secondaryText.withOpacity(0.4)),
                    const SizedBox(height: 10),
                    Text(
                      l10n.translate('noTransfers'),
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeTransfers.length,
                itemBuilder: (context, index) {
                  final record = activeTransfers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              record.direction.name == 'outgoing'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: AppColors.primaryAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.peerName ?? 'Unknown Device',
                                style: const TextStyle(
                                  color: AppColors.mainText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              record.status.name.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.secondaryAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: record.progressPercentage / 100.0,
                            backgroundColor: AppColors.elevatedSurface,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryAccent),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(record.transferredBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(record.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                            ),
                            Text(
                              '${record.progressPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.mainText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              break;
            case 1:
              context.push('/transfers');
              break;
            case 2:
              context.push('/cloud-share');
              break;
            case 3:
              context.push('/devices');
              break;
            case 4:
              context.push('/settings');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_vert_outlined),
            selectedIcon: const Icon(Icons.swap_vert),
            label: l10n.translate('transfers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: const Icon(Icons.cloud),
            label: l10n.translate('share'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.devices_outlined),
            selectedIcon: const Icon(Icons.devices),
            label: l10n.translate('devices'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.translate('settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.mainText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
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
