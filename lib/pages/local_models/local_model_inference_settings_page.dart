import 'package:flutter/material.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';
import 'package:nitmgpt/state/local_model_inference_prefs.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class LocalModelInferenceSettingsPage extends StatefulWidget {
  const LocalModelInferenceSettingsPage({
    super.key,
    required this.modelId,
  });

  final String modelId;

  @override
  State<LocalModelInferenceSettingsPage> createState() =>
      _LocalModelInferenceSettingsPageState();
}

class _LocalModelInferenceSettingsPageState
    extends State<LocalModelInferenceSettingsPage> {
  late LocalModelInferencePrefs _prefs;
  late LocalModelInferenceConfig _config;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _prefs = AppScope.of(context).localModelInference;
    _config = _prefs.read(widget.modelId);
  }

  void _update(LocalModelInferenceConfig Function(LocalModelInferenceConfig) fn) {
    final next = fn(_config);
    _prefs.write(widget.modelId, next);
    setState(() => _config = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }

    final modelName = displayNameFromFilename(widget.modelId);
    final sectionHeaderStyle = TextStyle(fontSize: 14, color: primaryColor);
    final topInset = SecondaryPageScaffold.scrollTopPadding(context);

    return SignalBuilder(
      builder: (context) {
        appLocale.value;

        return SecondaryPageScaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 32),
            children: [
              SecondaryPageScaffold.largeTitle('Model settings'.tr),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  modelName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Inference settings for this model only. Lower temperature and top K improve consistency for notification filtering.'
                      .tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              OpaqueGroupedSection(
                header: 'Generation'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  _SliderTile(
                    title: 'Max tokens'.tr,
                    subtitle: 'Maximum output length per request'.tr,
                    valueLabel: '${_config.maxTokens}',
                    value: _config.maxTokens.toDouble(),
                    min: 64,
                    max: 1024,
                    divisions: 15,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(maxTokens: v.round()),
                    ),
                  ),
                  _SliderTile(
                    title: 'Temperature'.tr,
                    subtitle:
                        'Lower values make classification more deterministic'.tr,
                    valueLabel: _config.temperature.toStringAsFixed(2),
                    value: _config.temperature,
                    min: 0,
                    max: 2,
                    divisions: 40,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(temperature: v),
                    ),
                  ),
                  _SliderTile(
                    title: 'Top K'.tr,
                    subtitle: '1 = greedy decoding (recommended for filtering)'.tr,
                    valueLabel: '${_config.topK}',
                    value: _config.topK.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(topK: v.round()),
                    ),
                  ),
                  _SliderTile(
                    title: 'Top P'.tr,
                    subtitle: 'Nucleus sampling threshold'.tr,
                    valueLabel: _config.topP.toStringAsFixed(2),
                    value: _config.topP,
                    min: 0.1,
                    max: 1,
                    divisions: 18,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(topP: v),
                    ),
                  ),
                ],
              ),
              OpaqueGroupedSection(
                header: 'Session'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  _SliderTile(
                    title: 'Token buffer'.tr,
                    subtitle: 'Reserved context space for chat history'.tr,
                    valueLabel: '${_config.tokenBuffer}',
                    value: _config.tokenBuffer.toDouble(),
                    min: 64,
                    max: 512,
                    divisions: 14,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(tokenBuffer: v.round()),
                    ),
                  ),
                  _SliderTile(
                    title: 'Random seed'.tr,
                    subtitle: 'Fixed seed for reproducible outputs'.tr,
                    valueLabel: '${_config.randomSeed}',
                    value: _config.randomSeed.toDouble(),
                    min: 1,
                    max: 9999,
                    divisions: 99,
                    onChanged: (v) => _update(
                      (c) => c.copyWith(randomSeed: v.round()),
                    ),
                  ),
                ],
              ),
              OpaqueGroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(UniconsLine.redo, color: primaryColor),
                    title: Text('Reset to defaults'.tr),
                    subtitle: Text(
                      'Restore settings tuned for notification filtering'.tr,
                    ),
                    onTap: () => _update((_) => LocalModelInferenceConfig.defaults),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(
            valueLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
