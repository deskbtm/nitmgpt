import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/gemma_model_store.dart';
import 'package:nitmgpt/theme.dart';

enum _ActivePicker { none, modelType, fileType }

Future<void> showAddModelSheet({
  required BuildContext context,
  required GemmaModelStore store,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet<void>(
    context: context,
    expand: false,
    enableDrag: true,
    builder: (sheetContext) => _AddModelSheet(
      store: store,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _AddModelSheet extends StatefulWidget {
  const _AddModelSheet({
    required this.store,
    required this.onClose,
  });

  final GemmaModelStore store;
  final VoidCallback onClose;

  @override
  State<_AddModelSheet> createState() => _AddModelSheetState();
}

class _AddModelSheetState extends State<_AddModelSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;
  late final FixedExtentScrollController _modelTypePickerController;
  late final FixedExtentScrollController _fileTypePickerController;

  ModelType _selectedType = ModelType.gemmaIt;
  ModelFileType _selectedFileType = ModelFileType.task;
  _ActivePicker _activePicker = _ActivePicker.none;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _tokenController = TextEditingController(
      text: huggingFaceToken.isNotEmpty ? huggingFaceToken : '',
    );
    _modelTypePickerController = FixedExtentScrollController(
      initialItem: ModelType.values.indexOf(_selectedType),
    );
    _fileTypePickerController = FixedExtentScrollController(
      initialItem: ModelFileType.values.indexOf(_selectedFileType),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _modelTypePickerController.dispose();
    _fileTypePickerController.dispose();
    super.dispose();
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

  bool _validateUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _urlError = 'Model URL is required'.tr);
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _urlError = 'Enter a valid model URL'.tr);
      return false;
    }
    setState(() => _urlError = null);
    return true;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validateUrl()) return;

    widget.onClose();
    final token = _tokenController.text.trim();
    await widget.store.installFromNetwork(
      url: _urlController.text,
      modelType: _selectedType,
      fileType: _selectedFileType,
      token: token.isEmpty ? null : token,
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: false,
          onChanged: errorText != null ? (_) => setState(() => _urlError = null) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            border: errorText != null
                ? Border.all(color: CupertinoColors.destructiveRed)
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ],
      ],
    );
  }

  void _togglePicker(_ActivePicker picker) {
    setState(() {
      if (_activePicker == picker) {
        _activePicker = _ActivePicker.none;
        return;
      }
      _activePicker = picker;
      if (picker == _ActivePicker.modelType) {
        _modelTypePickerController.jumpToItem(
          ModelType.values.indexOf(_selectedType),
        );
      } else if (picker == _ActivePicker.fileType) {
        _fileTypePickerController.jumpToItem(
          ModelFileType.values.indexOf(_selectedFileType),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scrollController = ModalScrollController.of(context);

    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add model'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: widget.onClose,
                        child: Text('Cancel'.tr),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _fieldLabel('Model download URL'.tr),
                      _textField(
                        controller: _urlController,
                        placeholder: 'https://...',
                        keyboardType: TextInputType.url,
                        errorText: _urlError,
                      ),
                      const SizedBox(height: 16),
                      OpaqueGroupedSection(
                        header: 'Model settings'.tr,
                        headerStyle: TextStyle(fontSize: 14, color: primaryColor),
                        margin: EdgeInsets.zero,
                        children: [
                          OpaqueListTile(
                            title: Text('Model type'.tr),
                            trailing: Text(_modelTypeLabel(_selectedType)),
                            onTap: () => _togglePicker(_ActivePicker.modelType),
                          ),
                          OpaqueListTile(
                            title: Text('File type'.tr),
                            trailing: Text(_selectedFileType.name),
                            onTap: () => _togglePicker(_ActivePicker.fileType),
                          ),
                        ],
                      ),
                      if (_activePicker == _ActivePicker.modelType) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: CupertinoPicker(
                            scrollController: _modelTypePickerController,
                            itemExtent: 36,
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedType = ModelType.values[index]);
                            },
                            children: ModelType.values
                                .map((t) => Center(child: Text(_modelTypeLabel(t))))
                                .toList(),
                          ),
                        ),
                      ],
                      if (_activePicker == _ActivePicker.fileType) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: CupertinoPicker(
                            scrollController: _fileTypePickerController,
                            itemExtent: 36,
                            onSelectedItemChanged: (index) {
                              setState(
                                () => _selectedFileType = ModelFileType.values[index],
                              );
                            },
                            children: ModelFileType.values
                                .map((t) => Center(child: Text(t.name)))
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _fieldLabel('HuggingFace token (optional)'.tr),
                      _textField(
                        controller: _tokenController,
                        placeholder: 'hf_...',
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _submit,
                      child: Text('Download'.tr),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
