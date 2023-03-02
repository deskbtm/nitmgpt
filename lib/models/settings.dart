import 'package:realm/realm.dart';
part 'settings.g.dart';

@RealmModel()
class _RuleFields {
  late String isAdMeaning;

  late String adProbabilityMeaning;

  late String isSpamMeaning;

  late String spamProbabilityMeaning;

  late String sentenceMeaning;

  Map<String, dynamic> toMap() {
    return {
      'isAdMeaning': isAdMeaning,
      'isSpamMeaning': isSpamMeaning,
      'adProbabilityMeaning': adProbabilityMeaning,
      'spamProbabilityMeaning': spamProbabilityMeaning,
      'sentenceMeaning': sentenceMeaning,
    };
  }
}

@RealmModel()
class _Settings {
  @PrimaryKey()
  late int id;

  /// Proxy uri
  String? proxyUri;

  /// OpenAi Api Key https://platform.openai.com/account/api-keys
  String? openAiKey;

  /// Preset Advertisement probability
  double? presetAdProbability;

  /// Preset spam probability
  double? presetSpamProbability;

  /// Rule fields
  _RuleFields? ruleFields;

  List<String> ignoredApps = [];
}
