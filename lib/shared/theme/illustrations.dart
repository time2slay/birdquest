import 'package:flutter/material.dart';

/// UI illustrations (generated with Google Flow / Nano Banana for BirdQuest).
/// These are decorative art only; they never depict a specific bird species.
///
/// Each `.png` has a night variant named `*_dark.png`.
abstract final class Illustrations {
  static const emptyCollection = 'assets/illustrations/empty_collection.png';
  static const listeningForest = 'assets/illustrations/listening_forest.png';
  static const offlineModel = 'assets/illustrations/offline_model.png';
  static const topoTexture = 'assets/illustrations/topo_texture.jpg';

  /// Picks the night variant of [asset] when the theme is dark.
  static String forBrightness(BuildContext context, String asset) =>
      Theme.of(context).brightness == Brightness.dark
      ? asset.replaceFirst('.png', '_dark.png')
      : asset;
}
