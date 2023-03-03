import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: must_be_immutable
class DoublePopExit extends StatelessWidget {
  final Widget child;
  DateTime? _lastPressedTime;

  DoublePopExit({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        if (_lastPressedTime == null ||
            (_lastPressedTime != null &&
                DateTime.now().difference(_lastPressedTime!) >
                    const Duration(milliseconds: 800))) {
          _lastPressedTime = DateTime.now();
          Fluttertoast.showToast(
            msg: "Press once again",
          );
          return false;
        }
        return true;
      },
    );
  }
}
