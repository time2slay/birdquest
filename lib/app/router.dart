import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/bird_details/bird_details_screen.dart';
import '../features/bird_details/camera_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/sightings/encounter_detail_screen.dart';
import '../features/sightings/species_history_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ScannerScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collection',
              builder: (_, _) => const CollectionScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/details/:key',
      parentNavigatorKey: _rootKey,
      builder: (_, s) =>
          BirdDetailsScreen(speciesKey: s.pathParameters['key']!),
    ),
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, _) =>
          const MaterialPage(fullscreenDialog: true, child: CameraScreen()),
    ),
    GoRoute(
      path: '/species/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, s) =>
          SpeciesHistoryScreen(speciesId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/encounter/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, s) =>
          EncounterDetailScreen(sightingId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const AboutScreen(),
    ),
  ],
);

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_outlined),
            selectedIcon: Icon(Icons.graphic_eq_rounded),
            label: 'Listen',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark_rounded),
            label: 'Collection',
          ),
        ],
      ),
    );
  }
}
