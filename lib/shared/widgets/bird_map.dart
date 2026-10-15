import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/material.dart' as material show Theme;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'photo_credit.dart';

/// OpenFreeMap vector styles (OpenStreetMap data, free, no API key).
abstract final class MapStyles {
  static const day = 'https://tiles.openfreemap.org/styles/liberty';
  static const night = 'https://tiles.openfreemap.org/styles/dark';
}

final mapStyleProvider = FutureProvider.family<Style, Brightness>((
  ref,
  brightness,
) async {
  final style = await StyleReader(
    uri: brightness == Brightness.dark ? MapStyles.night : MapStyles.day,
    httpHeaders: const {'User-Agent': 'BirdQuest/1.0 (Flutter map)'},
  ).read();
  // Neither OpenFreeMap style has an "id", so both themes are named
  // "default" and share rendered-tile caches: day tiles came out dark.
  return Style(
    name: style.name,
    theme: style.theme.copyWith(id: 'openfreemap-${brightness.name}'),
    providers: style.providers,
    sprites: style.sprites,
    center: style.center,
    zoom: style.zoom,
  );
});

/// Map base used across the app: OpenFreeMap tiles matching the app theme,
/// OSM attribution, and [layers] (markers etc.) on top.
class BirdMap extends ConsumerWidget {
  const BirdMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 11,
    this.controller,
    this.layers = const [],
    this.onTap,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final MapController? controller;
  final List<Widget> layers;
  final void Function(TapPosition, LatLng)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = material.Theme.of(context).brightness;
    final style = ref.watch(mapStyleProvider(brightness));
    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 2,
            maxZoom: 18,
            backgroundColor: context.nature.canvas,
            onTap: onTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (style.value case final s?)
              VectorTileLayer(
                key: ValueKey(brightness),
                theme: s.theme,
                sprites: s.sprites,
                tileProviders: s.providers,
                maximumZoom: 18,
              ),
            ...layers,
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => openExternal(
                    context,
                    'https://www.openstreetmap.org/copyright',
                  ),
                ),
                TextSourceAttribution(
                  'OpenFreeMap',
                  prependCopyright: false,
                  onTap: () => openExternal(context, 'https://openfreemap.org'),
                ),
              ],
            ),
          ],
        ),
        if (style.hasError)
          Positioned(
            top: Space.md,
            left: Space.md,
            right: Space.md,
            child: Material(
              color: context.nature.ochreContainer,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 18),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        'Map tiles need an internet connection. Your '
                        'sightings are still shown.',
                        style: material.Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(mapStyleProvider(brightness)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
