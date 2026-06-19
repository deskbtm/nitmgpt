import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/utils/model_download_guide.dart';
import 'package:nitmgpt/theme/app_theme.dart';
import 'package:nitmgpt/utils/url.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

Future<void> showModelDownloadWizardSheet({
  required BuildContext context,
  VoidCallback? onContinueDownload,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet<void>(
    context: context,
    expand: false,
    enableDrag: true,
    builder: (sheetContext) => _ModelDownloadWizardSheet(
      onClose: () => Navigator.of(sheetContext).pop(),
      onContinueDownload: onContinueDownload,
    ),
  );
}

class _ModelDownloadWizardSheet extends StatefulWidget {
  const _ModelDownloadWizardSheet({
    required this.onClose,
    this.onContinueDownload,
  });

  final VoidCallback onClose;
  final VoidCallback? onContinueDownload;

  @override
  State<_ModelDownloadWizardSheet> createState() =>
      _ModelDownloadWizardSheetState();
}

class _ModelDownloadWizardSheetState extends State<_ModelDownloadWizardSheet> {
  ModelDownloadSource _source = ModelDownloadSource.modelScope;

  Future<void> _openSourceSite() async {
    await open(ModelDownloadGuide.homeUrl(_source));
  }

  void _continueToDownload() {
    widget.onClose();
    widget.onContinueDownload?.call();
  }

  Widget _sourceSegment(ModelDownloadSource value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _stepTile({required int index, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        borderRadius: kTileBorderRadiusAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            UniconsLine.lightbulb_alt,
            size: 18,
            color: primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scrollController = ModalScrollController.of(context);

    return SignalBuilder(
      builder: (context) {
        appLocale.value;
        final steps = ModelDownloadGuide.stepKeys(_source);
        final tips = ModelDownloadGuide.tipKeys(_source);

        return Material(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Model download guide'.tr,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onClose,
                            child: Text('Close'.tr),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          Text(
                            'Choose where to download based on your network.'
                                .tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 14),
                          CupertinoSlidingSegmentedControl<
                              ModelDownloadSource>(
                            groupValue: _source,
                            children: {
                              ModelDownloadSource.modelScope: _sourceSegment(
                                ModelDownloadSource.modelScope,
                                'ModelScope (China)'.tr,
                              ),
                              ModelDownloadSource.huggingFace: _sourceSegment(
                                ModelDownloadSource.huggingFace,
                                'Hugging Face'.tr,
                              ),
                            },
                            onValueChanged: (value) {
                              if (value == null) return;
                              setState(() => _source = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            ModelDownloadGuide.sourceLabelKey(_source).tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _source == ModelDownloadSource.modelScope
                                ? 'Recommended for users in mainland China.'.tr
                                : 'Recommended for users outside mainland China.'
                                    .tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (var i = 0; i < steps.length; i++)
                            _stepTile(index: i + 1, text: steps[i].tr),
                          const SizedBox(height: 4),
                          for (final tip in tips) _tipCard(tip.tr),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CupertinoButton.filled(
                            onPressed: _openSourceSite,
                            child: Text(
                              ModelDownloadGuide.openSiteButtonKey(_source).tr,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            onPressed: _continueToDownload,
                            child: Text('Continue to download'.tr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
