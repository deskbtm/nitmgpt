/// Model download sources for the in-app wizard.
enum ModelDownloadSource {
  modelScope,
  huggingFace,
}

/// Static URLs and step keys for the model download wizard.
abstract final class ModelDownloadGuide {
  static const modelScopeHomeUrl = 'https://www.modelscope.cn/models';
  static const huggingFaceHomeUrl = 'https://huggingface.co/models';

  static String homeUrl(ModelDownloadSource source) {
    return switch (source) {
      ModelDownloadSource.modelScope => modelScopeHomeUrl,
      ModelDownloadSource.huggingFace => huggingFaceHomeUrl,
    };
  }

  static String sourceLabelKey(ModelDownloadSource source) {
    return switch (source) {
      ModelDownloadSource.modelScope => 'ModelScope (China) label',
      ModelDownloadSource.huggingFace => 'Hugging Face',
    };
  }

  static String openSiteButtonKey(ModelDownloadSource source) {
    return switch (source) {
      ModelDownloadSource.modelScope => 'Open ModelScope',
      ModelDownloadSource.huggingFace => 'Open Hugging Face',
    };
  }

  /// i18n keys for numbered wizard steps (use `.tr` in UI).
  static List<String> stepKeys(ModelDownloadSource source) {
    return switch (source) {
      ModelDownloadSource.modelScope => [
          'Wizard step: open ModelScope',
          'Wizard step: pick on-device model',
          'Wizard step: copy ModelScope file URL',
          'Wizard step: paste URL in app',
        ],
      ModelDownloadSource.huggingFace => [
          'Wizard step: open Hugging Face',
          'Wizard step: pick gated model',
          'Wizard step: copy Hugging Face file URL',
          'Wizard step: paste URL and token',
        ],
    };
  }

  static List<String> tipKeys(ModelDownloadSource source) {
    return switch (source) {
      ModelDownloadSource.modelScope => [
          'Wizard tip: ModelScope file types',
          'Wizard tip: ModelScope mirror',
        ],
      ModelDownloadSource.huggingFace => [
          'Wizard tip: Hugging Face file types',
          'Wizard tip: Hugging Face token',
        ],
    };
  }
}
