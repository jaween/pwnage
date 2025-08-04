import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pwnage/pwnage_app.dart';
import 'package:pwnage/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const apiBaseUrl = String.fromEnvironment('SERVER_BASE_URL');
  final api = ApiService(baseUrl: apiBaseUrl);

  runApp(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: const PwnageApp(),
    ),
  );
}
