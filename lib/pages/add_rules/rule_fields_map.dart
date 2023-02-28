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

final ruleFieldsMap = {
  'is_ad': CustomField(
    field: '`is_ad` ',
    name: 'is_ad',
    means: ' means whether it is an advertisement ',
    textEditingController: TextEditingController(),
  ),
  'ad_probability': CustomField(
    field: '`ad_probability` ',
    name: 'ad_probability',
    means:
        ' means the probability that this sentence is classified as an advertisement ',
    textEditingController: TextEditingController(),
  ),
  'is_spam': CustomField(
    field: '`is_spam` ',
    name: 'is_spam',
    means: ' means whether it is spam ',
    textEditingController: TextEditingController(),
  ),
  'spam_probability': CustomField(
      field: '`spam_probability` ',
      name: 'spam_probability',
      means:
          ' means the probability that this sentence is classified as a spam ',
      textEditingController: TextEditingController(),
      width: 150),
  'sentence': CustomField(
    field: '`sentence` ',
    name: 'sentence',
    means: ' means the input sentence ',
    textEditingController: TextEditingController(),
  ),
};
