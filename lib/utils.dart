import 'dart:convert';

dynamic looseJSONParse(String content) {
  try {
    content = content.replaceAll("\n", "");
    var match = RegExp(r"((\[[^\}]{3,})?\{s*[^\}\{]{3,}?:.*\}([^\{]+\])?)")
        .firstMatch(content);
    String? val = match?.group(0);
    if (val != null) {
      return jsonDecode(val);
    }

    return null;
  } catch (e) {
    return null;
  }
}
