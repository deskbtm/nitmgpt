import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/pages/local_models/add_model_sheet.dart';
import 'package:nitmgpt/pages/local_models/local_model_test_chat_sheet.dart';
import 'package:nitmgpt/pages/local_models/model_download_wizard_sheet.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';
import 'package:nitmgpt/state/local_model_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

/// Secondary settings page — opaque content on [SecondaryPageScaffold] pattern.
class LocalModelsPage extends StatefulWidget {
  const LocalModelsPage({super.key});

  @override
  State<LocalModelsPage> createState() => _LocalModelsPageState();
}

class _LocalModelsPageState extends State<LocalModelsPage> {
  late LocalModelStore _store;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _store = AppScope.of(context).localModels;
      _store.init();
    }
  }

  String _formatSize(double mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _modelTypeLabel(ModelType type) {
    return switch (type) {
      ModelType.gemmaIt => 'Gemma IT',
      ModelType.gemma4 => 'Gemma 4',
      ModelType.deepSeek => 'DeepSeek',
      ModelType.qwen => 'Qwen',
      ModelType.qwen3 => 'Qwen 3',
      ModelType.llama => 'Llama',
      ModelType.hammer => 'Hammer',
      ModelType.functionGemma => 'Function Gemma',
      ModelType.phi => 'Phi',
      ModelType.general => 'General',
    };
  }

  Future<void> _showDownloadWizard(BuildContext modalHostContext) {
    return showModelDownloadWizardSheet(
      context: modalHostContext,
      onContinueDownload: () => _showAddModelDialog(modalHostContext),
    );
  }

  Future<void> _showAddModelDialog(BuildContext modalHostContext) {
    return showAddModelSheet(context: modalHostContext, store: _store);
  }

  Future<void> _showTestChatSheet(BuildContext modalHostContext) {
    return showLocalModelTestChatSheet(context: modalHostContext);
  }

  Future<void> _confirmUninstall(LocalModelEntry entry) async {
    await showAppAlertDialog(
      context: context,
      title: 'Uninstall model'.tr,
      message: '${'Remove model from device?'.tr}\n${entry.name}',
      confirmText: 'Uninstall'.tr,
      cancelText: 'Cancel'.tr,
      onCancel: (dialogContext) async {
        popDialog(dialogContext);
      },
      onConfirm: (dialogContext) async {
        popDialog(dialogContext);
        await _store.uninstall(entry.id);
      },
    );
  }

  Future<void> _cleanupOrphans() async {
    final deleted = await _store.cleanupOrphans();
    if (!mounted) return;
    await showAppAlertDialog(
      context: context,
      title: 'Storage cleanup completed'.tr,
      message: '${'Removed orphaned files'.tr}: $deleted',
    );
  }

  Widget _buildBody(BuildContext modalHostContext) {
    final sectionHeaderStyle = TextStyle(fontSize: 14, color: primaryColor);

    return SignalBuilder(
      builder: (context) {
        final loading = _store.isLoading.value;
        final installing = _store.isInstalling.value;
        final progress = _store.installProgress.value;
        final error = _store.errorMessage.value;
        final models = _store.models.value;
        final stats = _store.storageStats.value;
        final hasActive = _store.hasActiveModel.value;
        final activeId = _store.activeModelId.value;

        if (loading && models.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final topInset = SecondaryPageScaffold.scrollTopPadding(context);

        return RefreshIndicator(
          onRefresh: _store.refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 96),
            children: [
              SecondaryPageScaffold.largeTitle('Local models'.tr),
              const SizedBox(height: 16),
              if (error != null)
                OpaqueGroupedSection(
                  children: [
                    ListTile(
                      title: Text(
                        error.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              if (installing)
                OpaqueGroupedSection(
                  children: [
                    ListTile(
                      title: Text('Downloading model...'.tr),
                      subtitle: LinearProgressIndicator(
                        value: progress == null ? null : progress / 100,
                      ),
                      trailing: Text(progress == null ? '...' : '$progress%'),
                    ),
                  ],
                ),
              OpaqueGroupedSection(
                header: 'Get a model'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  OpaqueListTile(
                    leading: Icon(
                      UniconsLine.book_open,
                      size: 18,
                      color: primaryColor,
                    ),
                    title: Text('Model download guide'.tr),
                    subtitle: Text(
                      'ModelScope (China) or Hugging Face'.tr,
                    ),
                    showChevron: true,
                    horizontalTitleGap: 8,
                    minLeadingWidth: 22,
                    onTap: () => _showDownloadWizard(modalHostContext),
                  ),
                ],
              ),
              OpaqueGroupedSection(
                header: 'Active model'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  OpaqueListTile(
                    leading: Icon(
                      hasActive
                          ? UniconsLine.check_circle
                          : UniconsLine.times_circle,
                      size: 18,
                      color: hasActive ? primaryColor : Colors.grey,
                    ),
                    title: Text(
                      hasActive
                          ? (activeId == null
                              ? 'Active'.tr
                              : displayNameFromFilename(activeId))
                          : 'No active model'.tr,
                    ),
                    subtitle: Text(
                      hasActive
                          ? 'Ready for on-device inference'.tr
                          : 'Download and select a model below'.tr,
                    ),
                    horizontalTitleGap: 8,
                    minLeadingWidth: 22,
                  ),
                  if (hasActive && activeId != null)
                    OpaqueListTile(
                      leading: Icon(
                        UniconsLine.sliders_v,
                        size: 18,
                        color: primaryColor,
                      ),
                      title: Text('Model settings'.tr),
                      subtitle: Text(
                        'Max tokens, temperature, and sampling'.tr,
                      ),
                      showChevron: true,
                      horizontalTitleGap: 8,
                      minLeadingWidth: 22,
                      onTap: () => context.push(
                        AppRoutes.localModelSettingsFor(activeId),
                      ),
                    ),
                  if (hasActive)
                    OpaqueListTile(
                      leading: Icon(
                        UniconsLine.comment_alt_lines,
                        size: 18,
                        color: primaryColor,
                      ),
                      title: Text('Chat'.tr),
                      subtitle: Text('Try on-device inference'.tr),
                      showChevron: true,
                      horizontalTitleGap: 8,
                      minLeadingWidth: 22,
                      onTap: () => _showTestChatSheet(modalHostContext),
                    ),
                ],
              ),
              OpaqueGroupedSection(
                header: 'Installed models'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  if (models.isEmpty)
                    ListTile(
                      title: Text('No models installed'.tr),
                      subtitle: Text('Tap + to download a model'.tr),
                    )
                  else
                    ...models.map((entry) {
                      return ListTile(
                        title: Text(entry.name),
                        subtitle: Text(
                          '${_modelTypeLabel(entry.modelType)} · '
                          '${_formatSize(entry.sizeMb)} · '
                          '${entry.fileType.name}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (entry.isActive)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  UniconsLine.check,
                                  color: primaryColor,
                                ),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'settings') {
                                  context.push(
                                    AppRoutes.localModelSettingsFor(entry.id),
                                  );
                                } else if (action == 'activate') {
                                  await _store.setActive(entry.id);
                                } else if (action == 'uninstall') {
                                  await _confirmUninstall(entry);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'settings',
                                  child: Text('Model settings'.tr),
                                ),
                                PopupMenuItem(
                                  value: 'activate',
                                  enabled: !entry.isActive,
                                  child: Text('Set as active'.tr),
                                ),
                                PopupMenuItem(
                                  value: 'uninstall',
                                  child: Text(
                                    'Uninstall'.tr,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: entry.isActive
                            ? null
                            : () => _store.setActive(entry.id),
                      );
                    }),
                ],
              ),
              OpaqueGroupedSection(
                header: 'Storage'.tr,
                headerStyle: sectionHeaderStyle,
                margin: EdgeInsets.zero,
                children: [
                  ListTile(
                    title: Text('Total model storage'.tr),
                    trailing: Text(
                      stats == null ? '--' : _formatSize(stats.totalSizeMB),
                    ),
                  ),
                  if (stats != null && stats.orphanedFiles.isNotEmpty)
                    ListTile(
                      title: Text('Orphaned files'.tr),
                      subtitle: Text(
                        '${stats.orphanedFiles.length} · '
                        '${_formatSize(stats.orphanedSizeMB)}',
                      ),
                      trailing: TextButton(
                        onPressed: _cleanupOrphans,
                        child: Text('Clean up'.tr),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }

    return CupertinoScaffold(
      transitionBackgroundColor: const Color(0xFF0D1110),
      topRadius: const Radius.circular(kTileBorderRadius),
      body: Builder(
        builder: (modalHostContext) {
          return SecondaryPageScaffold(
            floatingActionButton: SignalBuilder(
              builder: (context) {
                if (_store.isInstalling.value) {
                  return const SizedBox.shrink();
                }
                return FloatingActionButton(
                  onPressed: () => _showAddModelDialog(modalHostContext),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  child: const Icon(UniconsLine.plus),
                );
              },
            ),
            body: _buildBody(modalHostContext),
          );
        },
      ),
    );
  }
}
