import 'package:flutter/material.dart';
import 'package:nitmgpt/core/app_bootstrap.dart';
import 'nitm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NITM());
  scheduleDeferredAppBootstrap();
}
