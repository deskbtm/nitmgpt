import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'nitm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Sentry.init(
    (options) {
      options.dsn = kReleaseMode ? SENTRY_DNS : '';
      options.debug = kDebugMode;
    },
    appRunner: () async {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
      ].request();

      if (statuses.values.every((v) => v.isGranted)) {
        runApp(const NITM());
      }
    },
  );
}
