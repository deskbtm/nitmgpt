import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DoublePopExit extends StatefulWidget {
  const DoublePopExit({super.key, required this.child});

  final Widget child;

  @override
  State<DoublePopExit> createState() => _DoublePopExitState();
}

class _DoublePopExitState extends State<DoublePopExit> {
  DateTime? _lastPressedTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_lastPressedTime == null ||
            DateTime.now().difference(_lastPressedTime!) >
                const Duration(milliseconds: 800)) {
          _lastPressedTime = DateTime.now();
          Fluttertoast.showToast(msg: 'Press once again');
          return;
        }
        await SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
