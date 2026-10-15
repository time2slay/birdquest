import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/illustrations.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/common.dart';

/// Whether the first-launch tutorial has been completed or skipped.
class OnboardingSetting extends Notifier<bool> {
  static const _key = 'onboarding_done';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> set(bool done) async {
    state = done;
    await ref.read(sharedPreferencesProvider).setBool(_key, done);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingSetting, bool>(
  OnboardingSetting.new,
);

class _Page {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    this.illustration,
    this.tips = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final String? illustration;
  final List<({IconData icon, String text})> tips;
}

List<_Page> _pages(bool ru) => [
  _Page(
    icon: Icons.graphic_eq_rounded,
    illustration: Illustrations.listeningForest,
    title: ru ? 'Добро пожаловать в BirdQuest' : 'Welcome to BirdQuest',
    body: ru
        ? 'Узнавайте птиц по голосу, собирайте коллекцию находок и '
              'открывайте, кто поёт рядом с вами.'
        : 'Recognize birds by their song, build a collection of your '
              'discoveries and find out who sings around you.',
    tips: [
      (
        icon: Icons.lock_outline_rounded,
        text: ru
            ? 'Звук распознаётся прямо на телефоне и никуда не отправляется.'
            : 'Sound is recognized on your phone and never uploaded.',
      ),
    ],
  ),
  _Page(
    icon: Icons.mic_rounded,
    illustration: Illustrations.offlineModel,
    title: ru ? '1. Слушайте' : '1. Listen',
    body: ru
        ? 'Нажмите «Start listening» и направьте телефон на звук. Каждую '
              'секунду BirdQuest анализирует последние 3 секунды записи.'
        : 'Tap "Start listening" and point your phone toward the sound. '
              'Every second BirdQuest analyzes the last 3 seconds of audio.',
    tips: [
      (
        icon: Icons.download_rounded,
        text: ru
            ? 'В первый раз скачается модель BirdNET (81 МБ) — лучше по Wi-Fi.'
            : 'The first time, the BirdNET model downloads (81 MB) — '
                  'Wi-Fi is best.',
      ),
      (
        icon: Icons.place_outlined,
        text: ru
            ? 'Фильтр по местоположению скрывает птиц, которых нет в вашем '
                  'регионе в это время года.'
            : 'The location filter hides birds that don\'t occur in your '
                  'area at this time of year.',
      ),
      (
        icon: Icons.help_outline_rounded,
        text: ru
            ? '«Uncertain» — модель не уверена. Послушайте ещё немного.'
            : '"Uncertain" means the model isn\'t sure — keep listening.',
      ),
    ],
  ),
  _Page(
    icon: Icons.bookmark_add_rounded,
    title: ru ? '2. Сохраняйте находки' : '2. Save discoveries',
    body: ru
        ? 'Нажмите на птицу в списке «Heard this session», чтобы открыть '
              'её карточку: голос, фото и описание.'
        : 'Tap a bird in "Heard this session" to open its card with the '
              'recording, a photo and a description.',
    tips: [
      (
        icon: Icons.photo_camera_outlined,
        text: ru
            ? '«Take photo» — сфотографируйте птицу, если увидели её.'
            : '"Take photo" — snap the bird if you can see it.',
      ),
      (
        icon: Icons.bookmark_added_outlined,
        text: ru
            ? '«Save discovery» добавляет одну встречу, сколько бы раз птица '
                  'ни пела за сессию.'
            : '"Save discovery" adds one encounter, however often the bird '
                  'sang this session.',
      ),
      (
        icon: Icons.my_location_rounded,
        text: ru
            ? 'С «Attach GPS location» находка появится на карте. Координаты '
                  'хранятся только на телефоне.'
            : 'With "Attach GPS location" it appears on the map. '
                  'Coordinates stay on your phone.',
      ),
    ],
  ),
  _Page(
    icon: Icons.map_rounded,
    title: ru ? '3. Карта и достижения' : '3. Map & achievements',
    body: ru
        ? 'Вкладка «Map» показывает ваши находки. Нажмите на значок птицы, '
              'чтобы увидеть, сколько раз её встречали в этом районе.'
        : 'The Map tab shows your sightings. Tap a bird pin to see how '
              'often it was spotted in that area.',
    tips: [
      (
        icon: Icons.collections_bookmark_outlined,
        text: ru
            ? '«Collection» — все ваши виды и история встреч.'
            : '"Collection" holds every species and its encounter history.',
      ),
      (
        icon: Icons.emoji_events_outlined,
        text: ru
            ? 'Кубок в «Collection» — 17 достижений: первая птица, совы, '
                  'утренний хор и другие.'
            : 'The trophy in Collection opens 17 achievements — first bird, '
                  'owls, dawn chorus and more.',
      ),
    ],
  ),
  _Page(
    icon: Icons.menu_book_rounded,
    illustration: Illustrations.emptyCollection,
    title: ru ? '4. Энциклопедия' : '4. Field guide',
    body: ru
        ? 'Во вкладке «Guide» можно скачать энциклопедию птиц выбранного '
              'района — с описаниями и фото — и читать её без интернета.'
        : 'In the Guide tab, download a field guide for any area — '
              'descriptions and photos — and read it offline.',
    tips: [
      (
        icon: Icons.translate_rounded,
        text: ru
            ? 'Описания на русском и английском. Язык меняется в настройках '
                  '(⋮ → Settings & about).'
            : 'Descriptions in English and Russian. Change the language in '
                  'Settings (⋮ → Settings & about).',
      ),
      (
        icon: Icons.replay_rounded,
        text: ru
            ? 'Это обучение можно открыть снова там же, в настройках.'
            : 'You can replay this tutorial from Settings too.',
      ),
    ],
  ),
];

/// First-launch tutorial: what each tab does, in the guide language.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingDoneProvider.notifier).set(true);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final pages = _pages(ru);
    final last = _page == pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SegmentedButton<GuideLanguage>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: GuideLanguage.en, label: Text('EN')),
            ButtonSegment(value: GuideLanguage.ru, label: Text('RU')),
          ],
          selected: {lang},
          onSelectionChanged: (s) => ref
              .read(guideLanguageModeProvider.notifier)
              .set(
                s.first == GuideLanguage.ru
                    ? GuideLanguageMode.ru
                    : GuideLanguageMode.en,
              ),
        ),
        actions: [
          if (!last)
            TextButton(
              onPressed: _finish,
              child: Text(ru ? 'Пропустить' : 'Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [for (final p in pages) _PageView(page: p)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.sm,
              Space.lg,
              Space.lg,
            ),
            child: Row(
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: Durations.medium2,
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : context.nature.mossContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _controller.nextPage(
                          duration: Durations.medium2,
                          curve: Curves.easeOut,
                        ),
                  child: Text(
                    last
                        ? (ru ? 'Начать' : 'Get started')
                        : (ru ? 'Далее' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Landscape: picture beside the text, so nothing is cut off.
        if (constraints.maxWidth > constraints.maxHeight * 1.2) {
          return Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.sm,
                  0,
                  Space.sm,
                ),
                child: SizedBox(
                  width: constraints.maxWidth * 0.38,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _picture(context, theme),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    Space.sm,
                    Space.lg,
                    0,
                  ),
                  children: _texts(theme),
                ),
              ),
            ],
          );
        }
        // Portrait: readable width on tablets, picture at most 40% of the
        // height.
        final width = constraints.maxWidth.clamp(0.0, 560.0);
        final side = Space.lg + (constraints.maxWidth - width) / 2;
        return ListView(
          padding: EdgeInsets.fromLTRB(side, Space.sm, side, 0),
          children: [
            SizedBox(
              height: (width / 1.6).clamp(0.0, constraints.maxHeight * 0.4),
              child: _picture(context, theme),
            ),
            const SizedBox(height: Space.xl),
            ..._texts(theme),
          ],
        );
      },
    );
  }

  Widget _picture(BuildContext context, ThemeData theme) {
    return page.illustration != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Image.asset(
              Illustrations.forBrightness(context, page.illustration!),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : DecoratedBox(
            decoration: forestCardDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Icon(
                  page.icon,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
  }

  List<Widget> _texts(ThemeData theme) {
    return [
      Text(page.title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: Space.sm),
      Text(page.body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
      const SizedBox(height: Space.lg),
      for (final tip in page.tips)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tip.icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(tip.text, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
    ];
  }
}
