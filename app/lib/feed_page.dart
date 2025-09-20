import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pwnage/repositories/posts_repository.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/widgets/logo.dart';
import 'package:pwnage/widgets/posts.dart';
import 'package:pwnage/widgets/sources.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  List<Post>? _posts;
  bool _hasShownFirstPosts = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(postsProvider, (prev, next) {
      final value = next.valueOrNull;
      if (value != null) {
        _updatePosts(value);
      }
    });
  }

  void _updatePosts(PostsState value) async {
    // Artificial delay to not overload the user with too many animations
    if (!_hasShownFirstPosts) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) {
        return;
      }
      setState(() => _hasShownFirstPosts = true);
    }

    setState(() => _posts = value.posts);
  }

  @override
  Widget build(BuildContext context) {
    // Avoids immediately losing existing posts on filter change
    final cachedPosts = _posts;
    if (cachedPosts != null) {
      return _Feed(posts: cachedPosts);
    }

    final posts = ref.watch(postsProvider);
    return switch (posts) {
      AsyncError() => posts.isLoading ? _Loading() : _SomethingWentWrong(),
      AsyncData() || AsyncLoading() || _ => _Feed(posts: null),
    };
  }
}

class _Feed extends ConsumerStatefulWidget {
  final List<Post>? posts;

  const _Feed({super.key, required this.posts});

  @override
  ConsumerState<_Feed> createState() => _FeedState();
}

class _FeedState extends ConsumerState<_Feed>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(child: Logo()),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: posts == null ? 0.0 : 1.0,
              child: SourcesButton(
                filter: Set.of(ref.read(postFilterProvider)),
                onUpdateFilter: (filter) =>
                    ref.read(postFilterProvider.notifier).filter = filter,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverList.separated(
          itemCount: posts?.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (posts == null) {
              return _LoadingEffect(
                loading: ref.watch(postsProvider.select((p) => p.isLoading)),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 550),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child:
                        PostContainer(
                              onTap: null,
                              child: PostPlaceholderContents(),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: const Duration(seconds: 1),
                              angle: 60 * (pi / 180),
                            ),
                  ),
                ),
              );
            }

            final post = posts[index];
            return Center(
              key: ValueKey(post.id),
              child: Container(
                constraints: BoxConstraints(maxWidth: 550),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 550),
                  child: PostContainer(
                    key: ValueKey(post.id),
                    onTap: () => _launch(post.url),
                    child: IgnorePointer(child: PostContents(post: post)),
                  ),
                ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }

  void _onScroll() {
    final scroll = _scrollController.position;
    final isLoadingMore =
        ref.read(postsProvider).valueOrNull?.isLoadingMore == true;
    const distanceFromBottom = 1500;
    if (!isLoadingMore &&
        scroll.userScrollDirection == ScrollDirection.reverse &&
        scroll.pixels >= scroll.maxScrollExtent - distanceFromBottom) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    const web = kIsWeb || kIsWasm;
    // Ensures links open on web and mobile (see web transient user activation)
    if (web || await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SomethingWentWrong extends StatelessWidget {
  const _SomethingWentWrong({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/jeremy_lol.webp')
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(
                begin: -6,
                end: 6,
                duration: const Duration(milliseconds: 200),
              )
              .then()
              .moveY(
                begin: 6,
                end: -6,
                duration: const Duration(milliseconds: 200),
              ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Something went wrong',
              style: TextTheme.of(context).titleLarge,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.goNamed('init'),
            child: Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _LoadingEffect extends StatefulWidget {
  final bool loading;
  final Duration duration;
  final Widget child;

  const _LoadingEffect({
    super.key,
    required this.loading,
    this.duration = const Duration(milliseconds: 600),
    required this.child,
  });

  @override
  State<_LoadingEffect> createState() => _LoadingEffectState();
}

class _LoadingEffectState extends State<_LoadingEffect>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.loading) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _LoadingEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.loading && widget.loading) {
      _startAnimation();
    } else if (oldWidget.loading && !widget.loading) {
      _stopAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: widget.loading ? 0.0 : 1.0,
        end: widget.loading ? 0.0 : 1.0,
      ),
      duration: widget.duration,
      builder: (context, value, child) {
        return AnimatedOpacity(
          duration: widget.duration,
          opacity: widget.loading ? 0.5 : 1.0,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              0.2126 + 0.7874 * value,
              0.7152 - 0.7152 * value,
              0.0722 - 0.0722 * value,
              0,
              0,
              0.2126 - 0.2126 * value,
              0.7152 + 0.2848 * value,
              0.0722 - 0.0722 * value,
              0,
              0,
              0.2126 - 0.2126 * value,
              0.7152 - 0.7152 * value,
              0.0722 + 0.9278 * value,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: child,
          ),
        );
      },
      child: widget.child
          .animate(controller: _controller, autoPlay: false)
          .shimmer(
            duration: const Duration(seconds: 1),
            angle: 60 * (pi / 180),
          ),
    );
  }

  void _startAnimation() => _controller.repeat();

  void _stopAnimation() {
    _controller.stop();
    _controller.forward();
  }
}
