import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }

  void _loadFonts() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.interTextTheme(),
      GoogleFonts.interTightTextTheme(),
    ]);
    if (mounted) {
      context.goNamed('feed');
    }
  }
}
