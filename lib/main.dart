import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const NothingToWearApp(),
    ),
  );
}

class NothingToWearApp extends StatelessWidget {
  const NothingToWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AppState, bool>((a) => a.currentUser != null);
    return MaterialApp(
      title: 'NothingToWear',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: loggedIn ? const MainShell() : const AuthFlow(),
    );
  }
}
