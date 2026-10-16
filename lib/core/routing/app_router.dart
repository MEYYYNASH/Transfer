import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_dashboard_screen.dart';
import '../../features/uploads/presentation/send_files_screen.dart';
import '../../features/downloads/presentation/receive_files_screen.dart';
import '../../features/sharing/presentation/cloud_share_screen.dart';
import '../../features/sharing/presentation/paste_download_screen.dart';
import '../../features/history/presentation/transfers_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/updates/presentation/update_center_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeDashboardScreen(),
    ),
    GoRoute(
      path: '/send',
      builder: (context, state) => const SendFilesScreen(),
    ),
    GoRoute(
      path: '/receive',
      builder: (context, state) => const ReceiveFilesScreen(),
    ),
    GoRoute(
      path: '/transfers',
      builder: (context, state) => const TransfersScreen(),
    ),
    GoRoute(
      path: '/cloud-share',
      builder: (context, state) => const CloudShareScreen(),
    ),
    GoRoute(
      path: '/paste-download',
      builder: (context, state) => const PasteDownloadScreen(),
    ),
    GoRoute(
      path: '/devices',
      builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/updates',
      builder: (context, state) => const UpdateCenterScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
