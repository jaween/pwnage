import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwnage/feed_page.dart';
import 'package:pwnage/init_page.dart';
import 'package:pwnage/not_found_page.dart';
import 'package:pwnage/repositories/posts_repository.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/transition.dart';

class PwnageApp extends StatelessWidget {
  const PwnageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouterBuilder(
      navigatorObservers: [],
      builder: (context, router) {
        return MaterialApp.router(routerConfig: router, theme: _buildTheme());
      },
    );
  }

  ThemeData _buildTheme() {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: Colors.red,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
    );
  }
}

class _RouterBuilder extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const _RouterBuilder({
    super.key,
    required this.navigatorObservers,
    required this.builder,
  });

  @override
  State<_RouterBuilder> createState() => _RouterBuilderState();
}

class _RouterBuilderState extends State<_RouterBuilder> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _initRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _router);
  }

  GoRouter _initRouter({String? initialLocation}) {
    return GoRouter(
      debugLogDiagnostics: kDebugMode,
      observers: widget.navigatorObservers,
      initialLocation: initialLocation ?? '/',
      overridePlatformDefaultLocation: true,
      errorBuilder: (context, state) => NotFoundPage(),
      routes: [
        GoRoute(
          path: '/',
          name: 'init',
          pageBuilder: (context, state) {
            return TopLevelTransitionPage(child: InitPage());
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: child),
                  Positioned(
                    left: MediaQuery.of(context).padding.left + 16,
                    right: MediaQuery.of(context).padding.right + 16,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    child: Center(child: _BottomNavigationBar()),
                  ),
                ],
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/feed',
              name: 'feed',
              pageBuilder: (context, state) {
                return TopLevelTransitionPage(child: FeedPage());
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 70,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(64)),
            color: Colors.white.withAlpha(50),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(64)),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 40,
              children: [
                IconButton(onPressed: () {}, icon: Icon(Icons.rss_feed)),
                IconButton(onPressed: () {}, icon: Icon(Icons.store)),
                IconButton(onPressed: () {}, icon: Icon(Icons.abc)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepAliveProviders extends ConsumerStatefulWidget {
  final Widget child;

  const _KeepAliveProviders({super.key, required this.child});

  @override
  ConsumerState<_KeepAliveProviders> createState() =>
      _KeepAliveProvidersState();
}

class _KeepAliveProvidersState extends ConsumerState<_KeepAliveProviders> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      apiServiceProvider,
      fireImmediately: true,
      (previous, next) {},
    );
    ref.listenManual(postsProvider, fireImmediately: true, (previous, next) {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
