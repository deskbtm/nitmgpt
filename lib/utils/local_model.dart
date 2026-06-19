// Pure helpers for local model URL parsing and validation.
// Kept free of flutter_gemma so unit tests stay fast and offline.

enum LocalModelFileKind {
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

LocalModelFileKind inferFileKind(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.task')) return LocalModelFileKind.task;
  if (lower.endsWith('.litertlm')) return LocalModelFileKind.litertlm;
  return LocalModelFileKind.binary;
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

String? validateModelFilename(String filename) {
  final lower = filename.trim().toLowerCase();
  if (lower.endsWith('.task') ||
      lower.endsWith('.litertlm') ||
      lower.endsWith('.bin') ||
      lower.endsWith('.tflite')) {
    return null;
  }
  return 'Unsupported model file type';
}

bool shouldSkipConcurrentInstall({required bool isInstalling}) {
  return isInstalling;
}

/// Resolves the on-disk path for an installed model.
///
/// Local imports register [fileSourcePath] or [externalPath]; network downloads
/// land under [documentsPath].
String resolveInstalledModelFilePath({
  String? fileSourcePath,
  String? externalPath,
  required String documentsPath,
}) {
  if (fileSourcePath != null && fileSourcePath.isNotEmpty) {
    return fileSourcePath;
  }
  if (externalPath != null && externalPath.isNotEmpty) {
    return externalPath;
  }
  return documentsPath;
}
