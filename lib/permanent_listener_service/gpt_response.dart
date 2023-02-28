class GPTResponse {
  final bool? isAd;
  final double? adProbability;
  final bool? isSpam;
  final double? spamProbability;

  GPTResponse(this.isAd, this.adProbability, this.isSpam, this.spamProbability);

  factory GPTResponse.fromJson(Map<String, dynamic> json) => GPTResponse(
        json['is_ad'] as bool,
        json['ad_probability'] as double,
        json['is_spam'] as bool,
        json['spam_probability'] as double,
      );

  Map<String, dynamic> toJson() => responseToJson(this);

  Map<String, dynamic> responseToJson(GPTResponse instance) =>
      <String, dynamic>{
        'is_ad': instance.isAd,
        'ad_probability': instance.adProbability,
        'is_spam': instance.isSpam,
        'spam_probability': instance.spamProbability,
      };
}
