import 'package:flutter/material.dart';
import 'package:mizan/app/home_shell.dart';
import 'package:mizan/core/theme/app_theme.dart';

class MizanApp extends StatelessWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
