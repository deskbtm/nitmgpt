import 'package:nitmgpt/models/settings.dart';

const _isAdDefault =
    'true if the content is promotional or advertising';
const _adProbabilityDefault =
    'confidence from 0.0 to 1.0 that the content is an advertisement';
const _isSpamDefault =
    'true if the content is unsolicited junk or low-value noise';
const _spamProbabilityDefault =
    'confidence from 0.0 to 1.0 that the content is spam';
const _sentenceDefault = 'the notification text being analyzed';

String formatFieldDefinitions(Settings? settings) {
  final custom = settings?.ruleFields?.toMap();
  return [
    'is_ad: ${custom?['isAdMeaning'] ?? _isAdDefault}',
    'ad_probability: ${custom?['adProbabilityMeaning'] ?? _adProbabilityDefault}',
    'is_spam: ${custom?['isSpamMeaning'] ?? _isSpamDefault}',
    'spam_probability: ${custom?['spamProbabilityMeaning'] ?? _spamProbabilityDefault}',
    'sentence: ${custom?['sentenceMeaning'] ?? _sentenceDefault}',
  ].join(', ');
}

String buildClassificationPrompt(
  String notificationText,
  String fieldDefinitions,
) {
  return 'Classify the notification below as advertising or spam. '
      'Notification: "$notificationText". '
      'Return JSON only with these fields: $fieldDefinitions';
}
