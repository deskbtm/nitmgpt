class HttpSetup {
  Duration sendTimeout;
  Duration connectTimeout;
  Duration receiveTimeout;
  String? proxyUrl;

  HttpSetup({
    this.sendTimeout = Duration.zero,
    this.connectTimeout = Duration.zero,
    this.receiveTimeout = Duration.zero,
    this.proxyUrl,
  });

  HttpSetup httpSetup() => HttpSetup()
    ..sendTimeout = Duration(seconds: 6)
    ..connectTimeout = Duration(seconds: 6)
    ..receiveTimeout = Duration(seconds: 6);
}
