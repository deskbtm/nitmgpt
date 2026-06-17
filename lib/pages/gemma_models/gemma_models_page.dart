import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/pages/gemma_models/add_model_sheet.dart';
import 'package:nitmgpt/pages/gemma_models/gemma_test_chat_sheet.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';
import 'package:nitmgpt/state/gemma_model_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

/// Secondary settings page — opaque content on [SecondaryPageScaffold] pattern.
class GemmaModelsPage extends StatefulWidget {
  const GemmaModelsPage({super.key});

  @override
  State<GemmaModelsPage> createState() => _GemmaModelsPageState();
}

class _GemmaModelsPageState extends State<GemmaModelsPage> {
  late GemmaModelStore _store;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _store = AppScope.of(context).gemmaModels;
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

  Future<void> _showAddModelDialog(BuildContext modalHostContext) {
    return showAddModelSheet(context: modalHostContext, store: _store);
  }

  Future<void> _showTestChatSheet(BuildContext modalHostContext) {
    return showGemmaTestChatSheet(context: modalHostContext, store: _store);
  }

  Future<void> _confirmUninstall(GemmaModelEntry entry) async {
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
              SecondaryPageScaffold.largeTitle('Model configuration'.tr),
              const SizedBox(height: 16),
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
              OpaqueGroupedSection(
                header: 'Active model'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  ListTile(
                    leading: Icon(
                      hasActive
                          ? UniconsLine.check_circle
                          : UniconsLine.times_circle,
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
                  ),
                  if (hasActive)
                    ListTile(
                      leading: Icon(UniconsLine.comment_alt_lines, color: primaryColor),
                      title: Text('Test chat'.tr),
                      subtitle: Text('Try on-device inference'.tr),
                      trailing: const Icon(UniconsLine.angle_right, size: 18),
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
                        trailing: entry.isActive
                            ? Icon(UniconsLine.check, color: primaryColor)
                            : PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'activate') {
                                    await _store.setActive(entry.id);
                                  } else if (action == 'uninstall') {
                                    await _confirmUninstall(entry);
                                  }
                                },
                                itemBuilder: (context) => [
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
