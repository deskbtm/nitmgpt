import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bottom_bar_models.dart';
import 'frosted_bar_surface.dart';

class FrostedSearchPill extends StatefulWidget {
  const FrostedSearchPill({
    super.key,
    required this.config,
    required this.isActive,
    required this.barBorderRadius,
    this.onFocusChanged,
  });

  final SearchBarConfig config;
  final bool isActive;
  final double barBorderRadius;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<FrostedSearchPill> createState() => _FrostedSearchPillState();
}

class _FrostedSearchPillState extends State<FrostedSearchPill> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.config.controller != null) {
      _controller = widget.config.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    if (widget.config.focusNode != null) {
      _focusNode = widget.config.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    if (widget.isActive && widget.config.autoFocusOnExpand) {
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted && widget.isActive) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant FrostedSearchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive &&
        widget.isActive &&
        widget.config.autoFocusOnExpand) {
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted && widget.isActive) _focusNode.requestFocus();
      });
    } else if (oldWidget.isActive && !widget.isActive) {
      _focusNode.unfocus();
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _onFocusChanged() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _handleClear() {
    _controller.clear();
    widget.config.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.config.searchIconColor ??
        CupertinoColors.label.resolveFrom(context);
    final micColor = widget.config.micIconColor ?? iconColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const expandThreshold = 90.0;
        final circular =
            (width - constraints.maxHeight).abs() < 2 || width < expandThreshold;

        if (!widget.isActive || width < expandThreshold) {
          return FrostedBarSurface(
            borderRadius: widget.barBorderRadius,
            circular: circular,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (widget.isActive && widget.config.expandWhenActive)
                  ? null
                  : () => widget.config.onSearchToggle(true),
              child: Center(
                child: widget.config.searchIcon ??
                    Icon(CupertinoIcons.search, color: iconColor),
              ),
            ),
          );
        }

        return FrostedBarSurface(
          borderRadius: widget.barBorderRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: _buildExpanded(iconColor, micColor),
          ),
        );
      },
    );
  }

  Widget _buildExpanded(Color iconColor, Color micColor) {
    final config = widget.config;
    final textColor =
        config.textColor ?? CupertinoColors.label.resolveFrom(context);

    Widget trailing;
    if (config.trailingBuilder != null) {
      trailing = config.trailingBuilder!(context);
    } else {
      trailing = AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: _hasText
            ? GestureDetector(
                key: const ValueKey('clear'),
                behavior: HitTestBehavior.opaque,
                onTap: _handleClear,
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: iconColor,
                  size: 18,
                ),
              )
            : GestureDetector(
                key: const ValueKey('mic'),
                behavior: HitTestBehavior.opaque,
                onTap: config.onMicTap,
                child: config.onMicTap != null
                    ? Icon(CupertinoIcons.mic_fill, color: micColor, size: 18)
                    : const SizedBox.shrink(),
              ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              focusNode: _focusNode,
              onTap: config.onSearchFieldTap,
              onChanged: config.onChanged,
              onSubmitted: config.onSubmitted,
              onTapOutside: config.onTapOutside,
              textInputAction: config.textInputAction,
              keyboardType: config.keyboardType,
              autocorrect: config.autocorrect,
              enableSuggestions: config.enableSuggestions,
              style: config.hintStyle ??
                  TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
              cursorColor: config.cursorColor,
              placeholder: config.hintText,
              placeholderStyle: (config.hintStyle ??
                      const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ))
                  .copyWith(color: iconColor),
              padding: EdgeInsets.zero,
              decoration: null,
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class FrostedDismissPill extends StatelessWidget {
  const FrostedDismissPill({
    super.key,
    required this.onTap,
    required this.pillSize,
    required this.barBorderRadius,
    this.cancelButtonColor,
    this.cancelIcon,
    this.cancelIconSize = 24,
  });

  final VoidCallback onTap;
  final double pillSize;
  final double barBorderRadius;
  final Color? cancelButtonColor;
  final Widget? cancelIcon;
  final double cancelIconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final iconColor = cancelButtonColor ??
        (isDark ? const Color(0xE6FFFFFF) : const Color(0xE6000000));

    return SizedBox(
      width: pillSize,
      height: pillSize,
      child: FrostedBarSurface(
        borderRadius: barBorderRadius,
        circular: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: cancelIcon ??
                  Icon(
                    CupertinoIcons.xmark,
                    color: iconColor,
                    size: cancelIconSize,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
