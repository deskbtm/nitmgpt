import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Tab item for [FrostedSearchableBottomBar].
class BottomBarTab {
  const BottomBarTab({
    this.label,
    required this.icon,
    this.activeIcon,
  });

  final String? label;
  final Widget icon;
  final Widget? activeIcon;
}

/// Configuration for the morphing search bar in [FrostedSearchableBottomBar].
class SearchBarConfig {
  const SearchBarConfig({
    required this.onSearchToggle,
    this.hintText = 'Search',
    this.collapsedTabWidth,
    this.collapsedLogoBuilder,
    this.searchIconColor,
    this.searchIcon,
    this.micIconColor,
    this.hintStyle,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.textColor,
    this.cursorColor,
    this.trailingBuilder,
    this.textInputAction,
    this.keyboardType,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onTapOutside,
    this.autoFocusOnExpand = false,
    this.expandWhenActive = true,
    this.showsCancelButton = true,
    this.cancelButtonColor,
    this.cancelIcon,
    this.cancelIconSize = 24,
    this.onSearchFocusChanged,
    this.onSearchFieldTap,
    this.onCancelTap,
  });

  final ValueChanged<bool> onSearchToggle;
  final String hintText;
  final double? collapsedTabWidth;
  final WidgetBuilder? collapsedLogoBuilder;
  final Color? searchIconColor;
  final Widget? searchIcon;
  final Color? micIconColor;
  final TextStyle? hintStyle;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final Color? textColor;
  final Color? cursorColor;
  final WidgetBuilder? trailingBuilder;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final bool enableSuggestions;
  final TapRegionCallback? onTapOutside;
  final bool autoFocusOnExpand;
  final bool expandWhenActive;
  final bool showsCancelButton;
  final Color? cancelButtonColor;
  final Widget? cancelIcon;
  final double cancelIconSize;
  final ValueChanged<bool>? onSearchFocusChanged;
  final VoidCallback? onSearchFieldTap;
  final VoidCallback? onCancelTap;
}

/// Controls how the tab pill is anchored during the search morph animation.
enum TabPillAnchor {
  start,
  center,
}

/// Where an extra button appears relative to the search pill.
enum ExtraButtonPosition {
  beforeSearch,
  afterSearch,
}
