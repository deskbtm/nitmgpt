import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(UniconsLine.angle_left_b),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
