import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwnage/repositories/posts_repository.dart';

class InitPage extends ConsumerStatefulWidget {
  const InitPage({super.key});

  @override
  ConsumerState<InitPage> createState() => _InitPageState();
}

class _InitPageState extends ConsumerState<InitPage> {
  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.invalidate(postsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }

  void _loadFonts() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.interTextTheme(),
      GoogleFonts.interTightTextTheme(),
      GoogleFonts.courierPrimeTextTheme(),
    ]);
    if (mounted) {
      context.goNamed('feed');
    }
  }
}
