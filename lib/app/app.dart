import 'package:flutter/material.dart';

import '../start/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Focus',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}