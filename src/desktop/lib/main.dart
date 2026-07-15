import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_theme.dart';
import 'shell/arynox_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: ArynoxApp(),
    ),
  );
}

class ArynoxApp extends StatelessWidget {
  const ArynoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox OS',
      debugShowCheckedModeBanner: false,
      theme: ArynoxTheme.light(),
      darkTheme: ArynoxTheme.dark(),
      themeMode: ThemeMode.system,
      home: const ArynoxShell(),
    );
  }
}
