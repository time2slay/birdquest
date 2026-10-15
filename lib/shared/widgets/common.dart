import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Model score shown as a percentage with an uncertainty hint.
class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.score, this.dense = false});

  final double score;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final nature = context.nature;
    final uncertain = score < 0.5;
    final bg = uncertain ? nature.ochreContainer : nature.mossContainer;
    final fg = uncertain ? const Color(0xFF6B4E0F) : const Color(0xFF244A2D);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            uncertain ? Icons.help_outline_rounded : Icons.graphic_eq_rounded,
            size: dense ? 13 : 15,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            uncertain
                ? 'Uncertain · ${(score * 100).round()}%'
                : '${(score * 100).round()}% score',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Small "DEMO" marker for simulated data.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.nature.clayContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'DEMO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF7A3A18),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Banner shown whenever simulated recognition is active.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: context.nature.clayContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 18,
            color: Color(0xFF7A3A18),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'DEMO MODE — simulated results, not real identifications.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF7A3A18),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: context.nature.mossContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.nature.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ],
      ),
    );
  }
}

/// Inline card for a recoverable problem.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
    this.tone = NoticeTone.warning,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final nature = context.nature;
    final theme = Theme.of(context);
    final bg = switch (tone) {
      NoticeTone.warning => nature.ochreContainer,
      NoticeTone.error => theme.colorScheme.errorContainer,
      NoticeTone.info => nature.mossContainer,
    };
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(message, style: theme.textTheme.bodyMedium),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: actions),
          ],
        ],
      ),
    );
  }
}

enum NoticeTone { warning, error, info }

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xs,
        Space.lg,
        Space.xs,
        Space.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
