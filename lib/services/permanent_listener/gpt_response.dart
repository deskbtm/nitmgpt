class GPTResponse {
  const GPTResponse(
    this.isAd,
    this.adProbability,
    this.isSpam,
    this.spamProbability,
  );

  final bool? isAd;
  final double? adProbability;
  final bool? isSpam;
  final double? spamProbability;

  factory GPTResponse.fromJson(Map<String, dynamic> json) => GPTResponse(
        json['is_ad'] as bool?,
        _asDouble(json['ad_probability']),
        json['is_spam'] as bool?,
        _asDouble(json['spam_probability']),
      );

  Map<String, dynamic> toJson() => {
        'is_ad': isAd,
        'ad_probability': adProbability,
        'is_spam': isSpam,
        'spam_probability': spamProbability,
      };
}

double? _asDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  }
  return value as double?;
}
