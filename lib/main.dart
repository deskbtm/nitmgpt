import 'package:flutter/material.dart';
import 'package:nitmgpt/firebase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'nitm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();

  Map<Permission, PermissionStatus> statuses = await [
    Permission.notification,
  ].request();

  if (statuses.values.every((v) => v.isGranted)) {
    runApp(const NITM());
  }
}
