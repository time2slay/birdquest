import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/providers.dart';
import '../../services/bird_recognition/bird_recognition_service.dart';
import '../../services/bird_recognition/model_manager.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/illustrations.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../progress/progress_widgets.dart';
import 'scanner_controller.dart';
import 'widgets/listen_button.dart';
import 'widgets/model_setup_card.dart';
import 'widgets/spectrogram_view.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerControllerProvider);
    final controller = ref.read(scannerControllerProvider.notifier);
    final demo = ref.watch(demoModeProvider);
    final geoEnabled = ref.watch(geoFilterEnabledProvider);
    final modelStatus = ref.watch(modelStatusProvider).value;
    final groups = state.sortedGroups;
    final theme = Theme.of(context);

    void setDemo(bool value) async {
      await controller.newSession();
      ref.read(demoModeProvider.notifier).set(value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BirdQuest'),
            Text(
              'Listen. Discover. Collect.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              switch (v) {
                case 'demo':
                  setDemo(!demo);
                case 'geo':
                  ref.read(geoFilterEnabledProvider.notifier).set(!geoEnabled);
                case 'new':
                  controller.newSession();
                case 'about':
                  context.push('/about');
              }
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'demo',
                checked: demo,
                enabled: !state.isBusy,
                child: const Text('Demo mode (simulated)'),
              ),
              CheckedPopupMenuItem(
                value: 'geo',
                checked: geoEnabled,
                enabled: !state.isBusy,
                child: const Text('Filter by my location'),
              ),
              PopupMenuItem(
                value: 'new',
                enabled: groups.isNotEmpty,
                child: const Text('Clear & start new session'),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Text('Settings & about'),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            sliver: SliverList.list(
              children: [
                if (demo) ...[
                  const DemoBanner(),
                  const SizedBox(height: Space.md),
                ],
                const LevelCard(),
                const SizedBox(height: Space.md),
                _ListeningHero(state: state, demo: demo),
                const SizedBox(height: Space.md),
                if (!demo && modelStatus is! ModelInstalled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: ModelSetupCard(onUseDemo: () => setDemo(true)),
                  ),
                if (state.permissionDenied)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: NoticeCard(
                      icon: Icons.mic_off_rounded,
                      title: 'Microphone access needed',
                      message: state.permanentlyDenied
                          ? 'Microphone access is turned off for BirdQuest. '
                                'Enable it in system settings to identify birds by sound.'
                          : 'BirdQuest listens to bird song to identify species. '
                                'Audio is analyzed on your phone and never uploaded.',
                      actions: [
                        FilledButton(
                          onPressed: state.permanentlyDenied
                              ? openAppSettings
                              : controller.start,
                          child: Text(
                            state.permanentlyDenied
                                ? 'Open settings'
                                : 'Allow microphone',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: NoticeCard(
                      icon: Icons.error_outline_rounded,
                      tone: NoticeTone.error,
                      title: 'Something went wrong',
                      message: state.error!,
                    ),
                  ),
                SectionHeader(
                  groups.isEmpty
                      ? 'Heard this session'
                      : 'Heard this session · ${groups.length}',
                  trailing: groups.isEmpty
                      ? null
                      : Text(
                          'Tap a bird to confirm',
                          style: theme.textTheme.bodySmall,
                        ),
                ),
              ],
            ),
          ),
          if (groups.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.forest_outlined,
                illustration: Illustrations.listeningForest,
                title: state.isListening
                    ? 'Listening for birds…'
                    : 'No birds heard yet',
                message: state.isListening
                    ? 'Hold your phone towards the sound and keep still. '
                          'Species appear here as soon as they are recognized.'
                    : 'Head outside, tap Start listening, and BirdQuest will '
                          'identify the birds singing around you.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                0,
                Space.lg,
                Space.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) => _DetectionTile(
                  group: groups[i],
                  demo: state.isDemo,
                  onTap: () => context.push(
                    '/details/${Uri.encodeComponent(groups[i].key)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListeningHero extends ConsumerWidget {
  const _ListeningHero({required this.state, required this.demo});

  final ScannerState state;
  final bool demo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(scannerControllerProvider.notifier);
    final theme = Theme.of(context);
    final level = state.levels.isEmpty ? 0.0 : state.levels.last;
    final statusText = switch (state.status) {
      ScannerStatus.idle =>
        state.groups.isEmpty ? 'Ready when you are' : 'Paused · results kept',
      ScannerStatus.starting => 'Preparing microphone…',
      ScannerStatus.listening =>
        demo ? 'Simulating birdsong…' : 'Listening on-device…',
      ScannerStatus.paused => 'Paused while the camera is open',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.xl,
        Space.lg,
        Space.lg,
      ),
      decoration: forestCardDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Column(
        children: [
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: Space.xs),
          Text(
            state.isListening
                ? '${state.windowsAnalyzed} sound windows analyzed'
                : 'Audio is analyzed on your phone and never uploaded',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: Space.sm),
          ListenButton(
            listening: state.isListening,
            busy: state.isBusy,
            level: level,
            compact: state.isListening || state.groups.isNotEmpty,
            onPressed: state.isListening ? controller.stop : controller.start,
          ),
          AnimatedOpacity(
            opacity: state.isListening ? 1 : 0.8,
            duration: Motion.medium,
            child: FramedSpectrogram(
              buffer: ref.watch(recognitionServiceProvider).spectrogram,
              active: state.isListening,
            ),
          ),
          if (state.geoFilter != null) ...[
            const SizedBox(height: Space.md),
            _GeoFilterChip(state: state.geoFilter!),
          ],
        ],
      ),
    );
  }
}

class _DetectionTile extends ConsumerWidget {
  const _DetectionTile({
    required this.group,
    required this.demo,
    required this.onTap,
  });

  final DetectionGroup group;
  final bool demo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final time = DateFormat.Hms().format(group.lastHeard);
    // Flashes whenever the bird sings again (a new hit), like a live list.
    return TweenAnimationBuilder<double>(
      key: ValueKey(group.hits),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, glow, child) => Card(
        color: Color.lerp(
          theme.cardTheme.color ?? theme.colorScheme.surface,
          context.nature.ochreContainer,
          glow,
        ),
        child: child,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: BirdImage(
                  name: group.species.commonName,
                  scientificName: group.species.scientificName,
                  borderRadius: BorderRadius.circular(Radii.md),
                  showPlaceholderLabel: false,
                  cacheWidth: 192,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            speciesDisplayName(
                              ref,
                              group.species.scientificName,
                              group.species.commonName,
                            ),
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (demo) ...[
                          const SizedBox(width: Space.sm),
                          const DemoBadge(),
                        ],
                      ],
                    ),
                    Text(
                      group.species.scientificName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ScoreChip(score: group.bestScore, dense: true),
                        Text(
                          '${group.hits}× · last $time',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              group.isSaved
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      semanticLabel: 'Saved',
                    )
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: context.nature.inkMuted,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeoFilterChip extends StatelessWidget {
  const _GeoFilterChip({required this.state});
  final GeoFilterState state;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (state) {
      GeoFilterActive(:final plausibleSpecies) => (
        Icons.place_rounded,
        'Filtered for your area · $plausibleSpecies species this week',
      ),
      GeoFilterLocating() => (Icons.my_location_rounded, 'Finding your area…'),
      GeoFilterUnavailable(:final reason) => (
        Icons.location_off_rounded,
        reason,
      ),
      GeoFilterOff() => (
        Icons.public_rounded,
        'Location filter off · all species worldwide',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
