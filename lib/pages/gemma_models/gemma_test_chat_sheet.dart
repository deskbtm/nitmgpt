import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/gemma_model_store.dart';
import 'package:nitmgpt/state/gemma_test_chat_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';

Future<void> showGemmaTestChatSheet({
  required BuildContext context,
  required GemmaModelStore store,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet<void>(
    context: context,
    expand: false,
    enableDrag: true,
    builder: (sheetContext) => _GemmaTestChatSheet(
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _GemmaTestChatSheet extends StatefulWidget {
  const _GemmaTestChatSheet({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<_GemmaTestChatSheet> createState() => _GemmaTestChatSheetState();
}

class _GemmaTestChatSheetState extends State<_GemmaTestChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final GemmaTestChatStore _chatStore;
  EffectCleanup? _scrollEffect;

  @override
  void initState() {
    super.initState();
    _chatStore = GemmaTestChatStore()..init();
    _scrollEffect = effect(() {
      _chatStore.messages.value;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollEffect?.call();
    _inputController.dispose();
    _scrollController.dispose();
    _chatStore.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text;
    _inputController.clear();
    await _chatStore.sendMessage(text);
  }

  Widget _buildHeader() {
    return SignalBuilder(
      builder: (context) {
        final generating = _chatStore.isGenerating.value;
        final label = _chatStore.modelLabel.value;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemma test chat'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (label != null)
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: generating ? null : _chatStore.clearChat,
                child: Text('Clear chat'.tr),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onClose,
                child: Text('Cancel'.tr),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(GemmaChatBubble bubble) {
    final alignment =
        bubble.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = bubble.isThinking
        ? CupertinoColors.systemGrey5.resolveFrom(context)
        : bubble.isUser
            ? primaryColor.withValues(alpha: 0.18)
            : CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final textColor = bubble.isThinking
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : CupertinoColors.label.resolveFrom(context);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: kTileBorderRadiusAll,
        ),
        child: Text(
          bubble.text.isEmpty ? '...' : bubble.text,
          style: TextStyle(
            fontSize: bubble.isThinking ? 12 : 15,
            color: textColor,
            fontStyle: bubble.isThinking ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SignalBuilder(
      builder: (context) {
        final initializing = _chatStore.isInitializing.value;
        final generating = _chatStore.isGenerating.value;
        final ready = _chatStore.isReady;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (generating)
                CupertinoButton(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  onPressed: _chatStore.stopGeneration,
                  child: Text('Stop'.tr),
                ),
              Expanded(
                child: CupertinoTextField(
                  controller: _inputController,
                  placeholder: 'Type a message'.tr,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: ready && !generating,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        CupertinoColors.tertiarySystemFill.resolveFrom(context),
                    borderRadius: kTileBorderRadiusAll,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.only(bottom: 2),
                onPressed:
                    initializing || !ready || generating ? null : _sendMessage,
                child: Icon(
                  CupertinoIcons.paperplane_fill,
                  color: initializing || !ready || generating
                      ? CupertinoColors.inactiveGray
                      : primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            children: [
              _buildHeader(),
              SignalBuilder(
                builder: (context) {
                  final error = _chatStore.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      error.tr,
                      style: const TextStyle(
                          color: CupertinoColors.destructiveRed),
                    ),
                  );
                },
              ),
              Expanded(
                child: SignalBuilder(
                  builder: (context) {
                    final initializing = _chatStore.isInitializing.value;
                    final bubbles = _chatStore.messages.value;

                    if (initializing) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(),
                            const SizedBox(height: 12),
                            Text('Loading model...'.tr),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: bubbles.length,
                      itemBuilder: (context, index) =>
                          _buildBubble(bubbles[index]),
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }
}
