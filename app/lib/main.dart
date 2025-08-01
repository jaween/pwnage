import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pwnage/pwnage_app.dart';
import 'package:pwnage/services/api_service.dart';

void main() async {
  const apiBaseUrl = String.fromEnvironment('SERVER_BASE_URL');
  final api = ApiService(baseUrl: apiBaseUrl);

  runApp(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: const PwnageApp(),
    ),
  );
}
