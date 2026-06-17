import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/glass_quality_cache.dart';
import 'package:nitmgpt/core/prefs_signal.dart';
import 'package:nitmgpt/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'nitm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await LiquidGlassWidgets.initialize();
  await FlutterGemma.initialize(
    huggingFaceToken: huggingFaceToken.isEmpty ? null : huggingFaceToken,
    inferenceEngines: const [
      LiteRtLmEngine(),
      MediaPipeEngine(),
    ],
  );
  await initAppPrefs();

  final savedGlassQuality = await GlassQualityCache.load();

  Map<Permission, PermissionStatus> statuses = await [
    Permission.notification,
  ].request();

  if (statuses.values.every((v) => v.isGranted)) {
    runApp(
      LiquidGlassWidgets.wrap(
        child: const NITM(),
        adaptiveQuality: true,
        theme: glassThemeData,
        adaptiveConfig: GlassAdaptiveScopeConfig(
          initialQuality: savedGlassQuality ?? GlassQuality.premium,
          minQuality: GlassQuality.standard,
          allowStepUp: true,
          onQualityChanged: (_, quality) => GlassQualityCache.save(quality),
        ),
      ),
    );
  }
}
