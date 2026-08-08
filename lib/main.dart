import 'package:flutter/material.dart';

import 'src/map_screen.dart';

void main() {
  runApp(const TapaikoWardApp());
}

class TapaikoWardApp extends StatelessWidget {
  const TapaikoWardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAPAIKO WARD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF003893),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
