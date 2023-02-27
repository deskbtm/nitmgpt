import 'package:flutter/material.dart';

var primaryColor = const Color.fromARGB(255, 116, 170, 156);

ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: primaryColor,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 3),
);
