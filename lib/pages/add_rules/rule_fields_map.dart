import 'package:flutter/widgets.dart';
import 'package:nitmgpt/models/settings.dart';

class CustomField {
  final String field;
  final String name;
  final String means;
  final TextEditingController textEditingController;
  double? width;

  CustomField({
    required this.field,
    required this.name,
    required this.means,
    required this.textEditingController,
    this.width = 200,
  });
}

const IS_AD =
    'true if the content is promotional or advertising';
const AD_PROBABILITY =
    'confidence from 0.0 to 1.0 that the content is an advertisement';
const IS_SPAM =
    'true if the content is unsolicited junk or low-value noise';
const SPAM_PROBABILITY =
    'confidence from 0.0 to 1.0 that the content is spam';
const SENTENCE = 'the notification text being analyzed';

final ruleFieldsMap = {
  'is_ad': CustomField(
    field: 'is_ad',
    name: 'isAdMeaning',
    means: IS_AD,
    textEditingController: TextEditingController(),
  ),
  'ad_probability': CustomField(
    field: 'ad_probability',
    name: 'adProbabilityMeaning',
    means: AD_PROBABILITY,
    textEditingController: TextEditingController(),
  ),
  'is_spam': CustomField(
    field: 'is_spam',
    name: 'isSpamMeaning',
    means: IS_SPAM,
    textEditingController: TextEditingController(),
  ),
  'spam_probability': CustomField(
      field: 'spam_probability',
      name: 'spamProbabilityMeaning',
      means: SPAM_PROBABILITY,
      textEditingController: TextEditingController(),
      width: 150),
  'sentence': CustomField(
    field: 'sentence',
    name: 'sentenceMeaning',
    means: SENTENCE,
    textEditingController: TextEditingController(),
  ),
};

String formatFieldDefinitions(Settings? settings) {
  return ruleFieldsMap.values
      .map((element) {
        final mean = settings?.ruleFields != null
            ? settings!.ruleFields!.toMap()[element.name]
            : element.means;
        return '${element.field}: $mean';
      })
      .join(', ');
}

String buildClassificationPrompt(String notificationText, String fieldDefinitions) {
  return 'Classify the notification below as advertising or spam. '
      'Notification: "$notificationText". '
      'Return JSON only with these fields: $fieldDefinitions';
}
