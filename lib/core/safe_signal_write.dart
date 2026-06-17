import 'dart:developer' as developer;

import 'package:signals/signals.dart';

/// Runs a signal write after async work; swallows [SignalEffectException] when
/// subscribers (e.g. disposed [SignalBuilder]) fail to rebuild.
void safeSignalWrite(void Function() write) {
  try {
    write();
  } on SignalEffectException catch (e, st) {
    developer.log(
      'Signal write skipped (subscriber rebuild failed)',
      name: 'nitmgpt.signals',
      error: e.error,
      stackTrace: e.stackTrace ?? st,
    );
  }
}
