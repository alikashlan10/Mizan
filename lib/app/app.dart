import 'package:flutter/material.dart';
import 'package:mizan/app/home_shell.dart';

class MizanApp extends StatelessWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const HomeShell(),
    );
  }
}
