import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

const _deviceChannel = MethodChannel('com.deskbtm.nitmgpt/device');

bool? _cachedAndroidEmulator;

/// Returns true when running on an Android emulator (AVD / goldfish / ranchu).
Future<bool> isAndroidEmulator() async {
  if (kIsWeb || !Platform.isAndroid) {
    return false;
  }
  if (_cachedAndroidEmulator != null) {
    return _cachedAndroidEmulator!;
  }

  var isEmulator = false;
  try {
    final result = await _deviceChannel.invokeMethod<bool>('isEmulator');
    isEmulator = result ?? false;
  } catch (_) {
    isEmulator = _isAndroidEmulatorHeuristic();
  }

  _cachedAndroidEmulator = isEmulator;
  return isEmulator;
}

bool _isAndroidEmulatorHeuristic() {
  const emulatorPaths = [
    '/sys/qemu',
    '/dev/qemu_pipe',
    '/dev/goldfish_pipe',
  ];
  for (final path in emulatorPaths) {
    if (File(path).existsSync()) {
      return true;
    }
  }

  try {
    final cpuInfo = File('/proc/cpuinfo').readAsStringSync().toLowerCase();
    if (cpuInfo.contains('goldfish') || cpuInfo.contains('ranchu')) {
      return true;
    }
  } catch (_) {}

  return false;
}

/// English i18n key — show via `.tr` in UI.
const kLitertLmEmulatorUnsupportedKey =
    'LiteRT models are not supported on Android emulators';

bool? _cachedLitertLmRuntimeSupported;

/// Whether `.litertlm` FFI inference can run on this device.
///
/// Android emulators (including arm64 AVDs) advertise SME2 in CPU flags but
/// cannot execute KleidiAI kernels inside [libLiteRtLm.so], causing SIGILL at
/// `kai_get_sme_vector_length_u8` during `litert_lm_engine_create`.
/// [PreferredBackend.cpu] does not disable those kernels.
Future<bool> isLitertLmRuntimeSupported() async {
  if (_cachedLitertLmRuntimeSupported != null) {
    return _cachedLitertLmRuntimeSupported!;
  }

  if (kIsWeb || !Platform.isAndroid) {
    _cachedLitertLmRuntimeSupported = true;
    return true;
  }

  final supported = !(await isAndroidEmulator());
  _cachedLitertLmRuntimeSupported = supported;
  if (!supported) {
    developer.log(
      'LiteRT-LM blocked: Android emulator lacks working SME2 kernels',
      name: 'nitmgpt.litert',
    );
  }
  return supported;
}

/// Throws [UnsupportedError] with [kLitertLmEmulatorUnsupportedKey] when
/// [.litertlm] inference would SIGILL (Android emulator).
Future<void> ensureLitertLmRuntimeSupported() async {
  if (await isLitertLmRuntimeSupported()) return;
  throw UnsupportedError(kLitertLmEmulatorUnsupportedKey);
}

/// LiteRT `.litertlm` models need a stable backend. Emulators lack NPU dispatch
/// libraries and reliable Vulkan/WebGPU, so force CPU there.
Future<PreferredBackend?> preferredLitertBackend() async {
  if (await isAndroidEmulator()) {
    developer.log(
      'Android emulator detected — using LiteRT CPU backend',
      name: 'nitmgpt.litert',
    );
    return PreferredBackend.cpu;
  }
  return null;
}
