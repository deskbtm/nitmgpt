import 'dart:convert';

/// Best-effort JSON extraction from model text.
dynamic looseJSONParse(String content) {
  try {
    content = content.replaceAll('\n', '');
    final match = RegExp(
      r'((\[[^\}]{3,})?\{s*[^\}\{]{3,}?:.*\}([^\{]+\])?)',
    ).firstMatch(content);
    final value = match?.group(0);
    if (value != null) {
      return jsonDecode(value);
    }
    return null;
  } catch (_) {
    return null;
  }
}

String normalizeAssistantStreamText(String text) {
  return text.replaceFirst(RegExp(r'^(?:\r?\n)+'), '');
}
