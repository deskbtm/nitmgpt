import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';
import 'package:nitmgpt/state/local_model_test_chat_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

Future<void> showLocalModelTestChatSheet({
  required BuildContext context,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet<void>(
    context: context,
    expand: false,
    enableDrag: true,
    builder: (sheetContext) => _LocalModelTestChatSheet(
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _LocalModelTestChatSheet extends StatefulWidget {
  const _LocalModelTestChatSheet({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<_LocalModelTestChatSheet> createState() =>
      _LocalModelTestChatSheetState();
}

class _LocalModelTestChatSheetState extends State<_LocalModelTestChatSheet> {
  static const _sheetHeightFactor = 0.88;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late LocalModelTestChatStore _chatStore;
  EffectCleanup? _scrollSub;
  EffectCleanup? _generatingSub;
  bool _chatReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chatReady) return;
    _chatReady = true;

    _chatStore = LocalModelTestChatStore(
      inferencePrefs: AppScope.of(context).localModelInference,
    );

    void scrollOnChatUpdate() {
      try {
        _scrollToBottom();
      } catch (_) {}
    }

    _scrollSub = _chatStore.messages.subscribe((_) => scrollOnChatUpdate());
    _generatingSub =
        _chatStore.isGenerating.subscribe((_) => scrollOnChatUpdate());
    unawaited(_chatStore.init());
  }

  @override
  void dispose() {
    _scrollSub?.call();
    _generatingSub?.call();
    _inputController.dispose();
    _scrollController.dispose();
    if (_chatReady) {
      unawaited(_chatStore.dispose());
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      try {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } catch (_) {}
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await _chatStore.sendMessage(text);
  }

  BorderRadius _bubbleRadius({required bool isUser, required bool isThinking}) {
    const r = 18.0;
    const tail = 6.0;
    if (isThinking) {
      return BorderRadius.circular(14);
    }
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(tail),
      );
    }
    return const BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(tail),
      bottomRight: Radius.circular(r),
    );
  }

  Widget _buildBubble(ChatBubble bubble) {
    final isUser = bubble.isUser;
    final background = bubble.isThinking
        ? CupertinoColors.systemGrey5.resolveFrom(context)
        : isUser
            ? primaryColor
            : CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final textColor = bubble.isThinking
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : isUser
            ? Colors.white
            : CupertinoColors.label.resolveFrom(context);
    const textHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: _bubbleRadius(
                isUser: isUser,
                isThinking: bubble.isThinking,
              ),
            ),
            child: Text(
              isUser || bubble.isThinking
                  ? bubble.text
                  : normalizeAssistantStreamText(bubble.text),
              textHeightBehavior: textHeightBehavior,
              style: TextStyle(
                fontSize: bubble.isThinking ? 12 : 15,
                color: textColor,
                fontStyle:
                    bubble.isThinking ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyLoading() {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 6, right: 48),
      child: Row(
        children: [
          CupertinoActivityIndicator(radius: 8),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String semanticsLabel,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final bg = backgroundColor ??
        CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final fg = iconColor ?? CupertinoColors.label.resolveFrom(context);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required bool initializing,
    required bool generating,
    required bool ready,
  }) {
    if (generating) {
      return _buildCircleIconButton(
        icon: UniconsSolid.square_full,
        semanticsLabel: 'Stop'.tr,
        onTap: _chatStore.stopGeneration,
        backgroundColor: primaryColor,
        iconColor: Colors.white,
      );
    }

    final enabled = !initializing && ready;
    return _buildCircleIconButton(
      icon: UniconsLine.plane_fly,
      semanticsLabel: 'Send'.tr,
      onTap: enabled ? _sendMessage : null,
      backgroundColor: enabled
          ? primaryColor
          : CupertinoColors.systemGrey4.resolveFrom(context),
      iconColor: Colors.white,
    );
  }

  Widget _buildHeader() {
    return SignalBuilder(
      builder: (context) {
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
                      'Chat'.tr,
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
                onPressed: widget.onClose,
                child: Text('Cancel'.tr),
              ),
            ],
          ),
        );
      },
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
              _buildCircleIconButton(
                icon: UniconsLine.trash_alt,
                semanticsLabel: 'Clear chat'.tr,
                onTap:
                    !initializing && !generating ? _chatStore.clearChat : null,
                iconColor: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: _inputController,
                  placeholder: 'Type a message'.tr,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted:
                      ready && !generating ? (_) => _sendMessage() : null,
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
              _buildActionButton(
                initializing: initializing,
                generating: generating,
                ready: ready,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_chatReady) {
      return const SizedBox.shrink();
    }

    return Material(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * _sheetHeightFactor,
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
                    final generating = _chatStore.isGenerating.value;
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

                    final waitingForReply =
                        generating && (bubbles.isEmpty || bubbles.last.isUser);

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: bubbles.length + (waitingForReply ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == bubbles.length) {
                          return _buildReplyLoading();
                        }
                        return _buildBubble(bubbles[index]);
                      },
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
