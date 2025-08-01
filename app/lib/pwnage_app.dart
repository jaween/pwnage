import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pwnage/feed_page.dart';
import 'package:pwnage/not_found_page.dart';
import 'package:pwnage/transition.dart';

class PwnageApp extends StatelessWidget {
  const PwnageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouterBuilder(
      navigatorObservers: [],
      builder: (context, router) {
        return MaterialApp.router(routerConfig: router);
      },
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
          name: 'feed',
          pageBuilder: (context, state) {
            return TopLevelTransitionPage(child: FeedPage());
          },
        ),
      ],
    );
  }
}
