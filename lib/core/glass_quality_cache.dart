import 'dart:io';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Persists settled [GlassQuality] across cold starts to skip adaptive warmup.
class GlassQualityCache {
  GlassQualityCache._();

  static GlassQuality? _memory;
  static const _fileName = 'glass_quality.cache';

  static Future<GlassQuality?> load() async {
    if (_memory != null) return _memory;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return null;
      final name = (await file.readAsString()).trim();
      _memory = GlassQuality.values.byName(name);
      return _memory;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(GlassQuality quality) async {
    _memory = quality;
    try {
      final dir = await getApplicationSupportDirectory();
      await File('${dir.path}/$_fileName').writeAsString(quality.name);
    } catch (_) {}
  }
}
