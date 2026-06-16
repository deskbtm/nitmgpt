// Pure helpers for Gemma model URL parsing and validation.
// Kept free of flutter_gemma so unit tests stay fast and offline.

enum GemmaModelFileKind {
  task,
  litertlm,
  binary,
}

String displayNameFromFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot <= 0) return filename;
  return filename.substring(0, dot);
}

String filenameFromUrl(String url) {
  return Uri.parse(url).pathSegments.last;
}

String filenameFromPath(String path) {
  return path.split(RegExp(r'[/\\]')).last;
}

GemmaModelFileKind inferFileKind(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.task')) return GemmaModelFileKind.task;
  if (lower.endsWith('.litertlm')) return GemmaModelFileKind.litertlm;
  return GemmaModelFileKind.binary;
}

String? validateModelUrl(String url) {
  if (url.trim().isEmpty) {
    return 'Model URL is required';
  }
  return null;
}

String? validateModelFilePath(String path) {
  if (path.trim().isEmpty) {
    return 'Model file is required';
  }
  return null;
}

bool shouldSkipConcurrentInstall({required bool isInstalling}) {
  return isInstalling;
}
