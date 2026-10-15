import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/bird_details/bird_details_screen.dart';
import '../features/bird_details/camera_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/encyclopedia/encyclopedia_download_screen.dart';
import '../features/encyclopedia/encyclopedia_screen.dart';
import '../features/encyclopedia/species_guide_screen.dart';
import '../features/map/sightings_map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/sightings/encounter_detail_screen.dart';
import '../features/sightings/species_history_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// [needsOnboarding] is checked on every navigation to `/`, so the tutorial
/// shows on first launch until it is finished or skipped.
GoRouter buildRouter({required bool Function() needsOnboarding}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  redirect: (_, state) =>
      state.matchedLocation == '/' && needsOnboarding() ? '/welcome' : null,
  routes: [
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AchievementAnnouncer(child: _HomeShell(shell: shell)),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ScannerScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (_, _) => const SightingsMapScreen(),
            ),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/guide',
              builder: (_, _) => const EncyclopediaScreen(),
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
      path: '/guide/download',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const EncyclopediaDownloadScreen(),
    ),
    GoRoute(
      path: '/guide/species/:sci',
      parentNavigatorKey: _rootKey,
      builder: (_, s) => SpeciesGuideScreen(
        scientificName: s.pathParameters['sci']!,
        fallbackName: s.uri.queryParameters['name'],
      ),
    ),
    GoRoute(
      path: '/achievements',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const AchievementsScreen(),
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark_rounded),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Guide',
          ),
        ],
      ),
    );
  }
}
