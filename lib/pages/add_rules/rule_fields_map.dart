import 'package:flutter/widgets.dart';

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

const IS_AD = 'means whether it is an advertisement';
const AD_PROBABILITY =
    'means the probability that this sentence is classified as an advertisement';
const IS_SPAM = 'means whether it is spam';
const SPAM_PROBABILITY =
    'means the probability that this sentence is classified as a spam';
const SENTENCE =
    'means the probability that this sentence is classified as a spam';

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
