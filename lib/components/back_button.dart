import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:unicons/unicons.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: const Icon(UniconsLine.angle_left_b),
      onPressed: () => context.pop(),
    );
  }
}
