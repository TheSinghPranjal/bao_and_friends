import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'screens/system/force_update_screen.dart';
import 'services/force_update_service.dart';
import 'services/stars_store.dart';
import 'theme/tt_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm shared star total so every status bar starts in sync.
  await StarsStore.total();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  var decision = ForceUpdateDecision.none;
  try {
    // Firebase is configured for Android in this project.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      decision = await ForceUpdateService.check();
    }
  } catch (e, st) {
    debugPrint('Force-update check skipped: $e\n$st');
  }

  runApp(TinyThinkApp(forceUpdate: decision));
}

class TinyThinkApp extends StatelessWidget {
  const TinyThinkApp({super.key, this.forceUpdate = ForceUpdateDecision.none});

  final ForceUpdateDecision forceUpdate;

  @override
  Widget build(BuildContext context) {
    if (forceUpdate.required) {
      return MaterialApp(
        title: 'Tiny Think – Bao & Friends',
        debugShowCheckedModeBanner: false,
        theme: buildTinyThinkTheme(),
        home: ForceUpdateScreen(decision: forceUpdate),
      );
    }

    final router = createAppRouter();
    return MaterialApp.router(
      title: 'Tiny Think – Bao & Friends',
      debugShowCheckedModeBanner: false,
      theme: buildTinyThinkTheme(),
      routerConfig: router,
    );
  }
}
