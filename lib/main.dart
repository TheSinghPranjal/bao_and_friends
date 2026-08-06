import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation/app_router.dart';
import 'theme/tt_typography.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const TinyThinkApp());
}

class TinyThinkApp extends StatelessWidget {
  const TinyThinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter();
    return MaterialApp.router(
      title: 'Tiny Think – Bao & Friends',
      debugShowCheckedModeBanner: false,
      theme: buildTinyThinkTheme(),
      routerConfig: router,
    );
  }
}
