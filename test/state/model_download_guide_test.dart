import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/utils/model_download_guide.dart';

void main() {
  group('ModelDownloadGuide', () {
    test('provides ModelScope home URL', () {
      expect(
        ModelDownloadGuide.homeUrl(ModelDownloadSource.modelScope),
        'https://www.modelscope.cn/models',
      );
    });

    test('provides Hugging Face home URL', () {
      expect(
        ModelDownloadGuide.homeUrl(ModelDownloadSource.huggingFace),
        'https://huggingface.co/models',
      );
    });

    test('includes four steps per source', () {
      expect(
        ModelDownloadGuide.stepKeys(ModelDownloadSource.modelScope).length,
        4,
      );
      expect(
        ModelDownloadGuide.stepKeys(ModelDownloadSource.huggingFace).length,
        4,
      );
    });
  });
}
