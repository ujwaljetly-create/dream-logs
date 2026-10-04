import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/dream_shell.dart';

class DreamLogsApp extends StatelessWidget {
  const DreamLogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dream Logs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DreamShell(),
    );
  }
}
