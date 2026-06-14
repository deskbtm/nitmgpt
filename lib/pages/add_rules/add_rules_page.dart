import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/device_apps_compat.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class ProbabilityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const ProbabilityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              subtitle,
              style: TextStyle(
                backgroundColor: primaryColor,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        const Text('>', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AddRulesPage extends StatefulWidget {
  const AddRulesPage({super.key});

  @override
  State<AddRulesPage> createState() => _AddRulesPageState();
}

class _AddRulesPageState extends State<AddRulesPage> {
  final _formKey = GlobalKey<FormState>();
  final _selectedApps = signal<List<ApplicationWithIcon>>([]);

  final _adProbabilityController = TextEditingController();
  final _spamProbabilityController = TextEditingController();
  final _limitController = TextEditingController();

  late SettingsStore _settingsStore;
  late Settings _settings;
  late WatcherStore _watcher;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _settingsStore = AppScope.of(context).settings;
      _settings = _settingsStore.settings;
      _watcher = AppScope.of(context).watcher;
      _loadFromSettings();
    }
  }

  void _loadFromSettings() {
    _setupQuestionFields();
    if (_settings.presetAdProbability != null) {
      _adProbabilityController.text =
          _settings.presetAdProbability.toString();
    }
    if (_settings.presetSpamProbability != null) {
      _spamProbabilityController.text =
          _settings.presetSpamProbability.toString();
    }
    _limitController.text = _settings.presetLimit.toString();
    _setupIgnoredApps();
  }

  @override
  void dispose() {
    for (final e in ruleFieldsMap.values) {
      if (e.textEditingController.text.isEmpty) {
        e.textEditingController.dispose();
      }
    }
    _spamProbabilityController.dispose();
    _adProbabilityController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    if (value != null && value.isEmpty) {
      return 'Please this field must be filled';
    }
    return null;
  }

  void _addSelectedApp(ApplicationWithIcon app) {
    if (_selectedApps.value.contains(app)) return;
    realm.write(() {
      _settings.ignoredApps.add(app.packageName);
    });
    _selectedApps.value = [..._selectedApps.value, app];
  }

  void _removeSelectedApp(ApplicationWithIcon app) {
    realm.write(() {
      _settings.ignoredApps.removeWhere((element) => element == app.packageName);
    });
    _selectedApps.value =
        _selectedApps.value.where((a) => a != app).toList();
  }

  void _setupQuestionFields() {
    for (final e in ruleFieldsMap.values) {
      if (_settings.ruleFields != null) {
        e.textEditingController.text =
            _settings.ruleFields!.toMap()[e.name];
      } else {
        e.textEditingController.text = e.means;
      }
    }
  }

  void _setupIgnoredApps() {
    final selected = <ApplicationWithIcon>[];
    for (final packageName in _settings.ignoredApps) {
      final app = _watcher.deviceApps.value
          .firstWhereOrNull((ele) => ele.packageName == packageName);
      if (app != null) {
        selected.add(app);
      }
    }
    _selectedApps.value = selected;
  }

  Future<void> _toggleIgnoreSystemApps(bool? value) async {
    _settingsStore.ignoreSystemApps.value = value ?? true;
  }

  Future<void> _submit() async {
    realm.write(() {
      _settings.ruleFields = RuleFields(
        ruleFieldsMap['is_ad']!.textEditingController.text,
        ruleFieldsMap['ad_probability']!.textEditingController.text,
        ruleFieldsMap['is_spam']!.textEditingController.text,
        ruleFieldsMap['spam_probability']!.textEditingController.text,
        ruleFieldsMap['sentence']!.textEditingController.text,
      );
    });

    realm.write(() {
      _settings.presetAdProbability =
          _adProbabilityController.text.isEmpty
              ? null
              : double.tryParse(_adProbabilityController.text);

      _settings.presetSpamProbability =
          _spamProbabilityController.text.isEmpty
              ? null
              : double.tryParse(_spamProbabilityController.text);

      final limitVal = int.tryParse(_limitController.text);
      if (_limitController.text.isNotEmpty && limitVal != null) {
        _settings.presetLimit = limitVal;
      }
    });
  }

  Future<void> _showDeviceApps() {
    return showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SignalBuilder(
          builder: (context) {
            final apps = _watcher.deviceApps.value;
            if (apps.isEmpty) {
              return const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 20),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return ListTile(
                  onTap: () {
                    _addSelectedApp(app);
                    popDialog(sheetContext);
                  },
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: AppIconImage(
                      bytes: app.icon,
                      width: 50,
                      height: 50,
                    ),
                  ),
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }

    final blockTextStyle = TextStyle(
      background: Paint()..color = primaryColor,
      color: Colors.white,
    );

    final fieldsBlock = ruleFieldsMap.values.map((e) {
      return TextSpan(
        children: [
          TextSpan(text: '\n${e.field}: '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: e.width,
              child: TextFormField(
                validator: _validator,
                controller: e.textEditingController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GlassScaffold(
        background: kAppGlassBackground,
        statusBarStyle: GlassStatusBarStyle.auto,
        edgeFade: false,
        appBar: GlassToolbarLayer(
          child: GlassAppBar(
            leading: const AppBarBackButton(),
          ),
        ),
        floatingActionButton: GlassButton.custom(
          useOwnLayer: true,
          quality: chromeGlassQuality,
          onTap: () async {
            if (_formKey.currentState?.validate() ?? false) {
              await _submit();
              if (!context.mounted) return;
              context.pop();
            }
          },
          height: 52,
          shape: const LiquidRoundedSuperellipse(borderRadius: 26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(UniconsLine.check, size: 18),
                const SizedBox(width: 8),
                Text('Done'.tr, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ignore apps'.tr,
                      style: TextStyle(fontSize: 14, color: primaryColor),
                    ),
                    Text(
                      'Some permanent notifications will always trigger notification check, so you need to ignore or close it'
                          .tr,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text('Ignore system apps'.tr),
                        SignalBuilder(
                          builder: (context) => GlassSwitch(
                            value: _settingsStore.ignoreSystemApps.value,
                            onChanged: _toggleIgnoreSystemApps,
                          ),
                        ),
                      ],
                    ),
                    SignalBuilder(
                      builder: (context) => GlassToolbarLayer(
                        quality: contentGlassQuality,
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              GlassButton.custom(
                                onTap: () async {
                                  _watcher.deviceApps.value = [];
                                  await _watcher.getDeviceApps();
                                  await _showDeviceApps();
                                },
                                height: 44,
                                shape: const LiquidRoundedSuperellipse(
                                  borderRadius: 12,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Select app'.tr,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              ..._selectedApps.value.map((element) {
                                return GlassChip(
                                  label: element.appName,
                                  icon: CircleAvatar(
                                    backgroundColor: Colors.grey.shade800,
                                    radius: 12,
                                    child: AppIconImage(
                                      bytes: element.icon,
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  onDeleted: () => _removeSelectedApp(element),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Filter criteria'.tr,
                      style: TextStyle(fontSize: 14, color: primaryColor),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 2.2,
                        ),
                        children: [
                          TextSpan(text: 'classification_prompt_intro'.tr),
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: 'classification_prompt_notification'.tr,
                          ),
                          const TextSpan(text: ' '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Text(
                              '{{template}}',
                              style: blockTextStyle,
                            ),
                          ),
                          const TextSpan(text: '\n'),
                          TextSpan(text: 'classification_prompt_json'.tr),
                          ...fieldsBlock,
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${'Limit'.tr} (24h ${'reset'.tr})',
                      style: TextStyle(fontSize: 14, color: primaryColor),
                    ),
                    Text(
                      'Maximum API calls per 24 hours'.tr,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _limitController,
                        validator: _validator,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Custom probability (0~1.0)'.tr,
                      style: TextStyle(fontSize: 14, color: primaryColor),
                    ),
                    Text(
                      'If set, remove the notification should be more than the probability set here'
                          .tr,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    ProbabilityTile(
                      validator: _validator,
                      title: 'Advertisement probability'.tr,
                      subtitle: '`ad_probability`',
                      controller: _adProbabilityController,
                    ),
                    const SizedBox(height: 10),
                    ProbabilityTile(
                      validator: _validator,
                      title: 'Spam probability'.tr,
                      subtitle: '`spam_probability`',
                      controller: _spamProbabilityController,
                    ),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
