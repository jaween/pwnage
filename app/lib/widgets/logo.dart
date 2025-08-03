import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/silhouette.webp', height: 60),
        SizedBox(height: 4),
        Text(
          'teh pwnage',
          textAlign: TextAlign.center,
          style: GoogleFonts.courierPrimeTextTheme(
            TextTheme.of(context),
          ).titleLarge?.copyWith(letterSpacing: 1),
        ),
        Text(
          'FEED',
          textAlign: TextAlign.center,
          style: GoogleFonts.interTextTheme(
            TextTheme.of(context),
          ).displayLarge?.copyWith(height: 0.8),
        ),
      ],
    );
  }
}
