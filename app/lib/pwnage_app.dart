import 'package:flutter/material.dart';

class PwnageApp extends StatelessWidget {
  const PwnageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Pwnage')),
      ),
    );
  }
}
