/// Sprite-sheet playback for hand-drawn familiars.
///
/// A sheet is `assets/images/familiars/<species>.png` with a JSON manifest
/// beside it (`<species>.json`) that names each animation's row, start
/// column, frame count and speed. See `assets/REQUIRED_ASSETS.md`.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';

class SpriteAnimation {
  const SpriteAnimation({
    required this.row,
    required this.frames,
    this.start = 0,
    this.fps = 8,
    this.loop = true,
  });

  final int row;
  final int frames;
  final int start;
  final double fps;
  final bool loop;

  static SpriteAnimation? fromJson(Object? json, double defaultFps) {
    if (json is! Map) return null;
    final row = (json['row'] as num?)?.toInt();
    final frames = (json['frames'] as num?)?.toInt();
    if (row == null || frames == null || frames <= 0) return null;
    return SpriteAnimation(
      row: row,
      frames: frames,
      start: (json['start'] as num?)?.toInt() ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? defaultFps,
      loop: json['loop'] != false,
    );
  }
}

class SpriteSheetManifest {
  const SpriteSheetManifest({
    required this.frameWidth,
    required this.frameHeight,
    required this.animations,
    this.facesRight = true,
  });

  final int frameWidth;
  final int frameHeight;
  final Map<String, SpriteAnimation> animations;

  /// Which way the art faces as drawn; the stage flips it as needed.
  final bool facesRight;

  /// Order in which actions borrow from others when the sheet lacks them.
  static const Map<FamiliarAction, List<String>> fallbacks = {
    FamiliarAction.idle: ['idle'],
    FamiliarAction.walk: ['walk', 'run', 'idle'],
    FamiliarAction.sit: ['sit', 'idle'],
    FamiliarAction.sleep: ['sleep', 'sit', 'idle'],
    FamiliarAction.groom: ['groom', 'sit', 'idle'],
    FamiliarAction.stretch: ['stretch', 'idle'],
    FamiliarAction.hop: ['hop', 'jump', 'walk', 'idle'],
  };

  SpriteAnimation? animationFor(FamiliarAction action) {
    for (final name in fallbacks[action]!) {
      final a = animations[name];
      if (a != null) return a;
    }
    return animations.values.firstOrNull;
  }

  static SpriteSheetManifest parse(String text) {
    final json = jsonDecode(text);
    if (json is! Map) throw const FormatException('Manifest is not an object');
    final w = (json['frameWidth'] as num?)?.toInt();
    final h = (json['frameHeight'] as num?)?.toInt();
    if (w == null || h == null || w <= 0 || h <= 0) {
      throw const FormatException('Manifest needs frameWidth and frameHeight');
    }
    final fps = (json['fps'] as num?)?.toDouble() ?? 8;
    final raw = json['animations'];
    final animations = <String, SpriteAnimation>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final a = SpriteAnimation.fromJson(entry.value, fps);
        if (a != null) animations[entry.key.toString()] = a;
      }
    }
    if (animations.isEmpty) {
      throw const FormatException('Manifest has no animations');
    }
    return SpriteSheetManifest(
      frameWidth: w,
      frameHeight: h,
      animations: animations,
      facesRight: json['facing'] != 'left',
    );
  }
}

/// A loaded sheet: manifest plus decoded image.
class SpriteSheet {
  const SpriteSheet({required this.manifest, required this.image});

  final SpriteSheetManifest manifest;
  final ui.Image image;

  static String pngAsset(String species) =>
      'assets/images/familiars/$species.png';
  static String manifestAsset(String species) =>
      'assets/images/familiars/$species.json';

  /// Loads the sheet for [species], or `null` when either file is missing
  /// or unreadable.
  static Future<SpriteSheet?> load(String species) async {
    try {
      final text = await rootBundle.loadString(manifestAsset(species));
      final manifest = SpriteSheetManifest.parse(text);
      final bytes = await rootBundle.load(pngAsset(species));
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return SpriteSheet(manifest: manifest, image: frame.image);
    } catch (_) {
      return null;
    }
  }
}

/// Draws one frame of [sheet] for [action] at time [seconds].
class SpriteSheetPainter extends CustomPainter {
  SpriteSheetPainter({
    required this.sheet,
    required this.action,
    required this.seconds,
    this.dimmed = false,
  });

  final SpriteSheet sheet;
  final FamiliarAction action;
  final double seconds;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final m = sheet.manifest;
    final anim = m.animationFor(action);
    if (anim == null) return;
    final raw = (seconds * anim.fps).floor();
    final index = anim.loop ? raw % anim.frames : raw.clamp(0, anim.frames - 1);
    final src = Rect.fromLTWH(
      (anim.start + index) * m.frameWidth.toDouble(),
      anim.row * m.frameHeight.toDouble(),
      m.frameWidth.toDouble(),
      m.frameHeight.toDouble(),
    );
    // Fit the frame into the box, bottom-aligned, keeping pixels crisp.
    final scale =
        (size.width / m.frameWidth < size.height / m.frameHeight)
            ? size.width / m.frameWidth
            : size.height / m.frameHeight;
    final dw = m.frameWidth * scale;
    final dh = m.frameHeight * scale;
    final dst = Rect.fromLTWH((size.width - dw) / 2, size.height - dh, dw, dh);
    canvas.drawImageRect(
      sheet.image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: dimmed ? 0.45 : 1),
    );
  }

  @override
  bool shouldRepaint(SpriteSheetPainter old) =>
      old.seconds != seconds ||
      old.action != action ||
      old.sheet != sheet ||
      old.dimmed != dimmed;
}
