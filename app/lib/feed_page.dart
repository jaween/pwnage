import 'dart:math';

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
  late final _logoController = AnimationController(vsync: this);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _Feed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts == null && widget.posts != null) {
      _logoController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.sizeOf(context).height / 4 - 60,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: posts == null ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: PwnageImminentText(),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final value = !_scrollController.hasClients
                        ? 1.0
                        : Curves.easeOutCubic.transform(
                            (1 - _scrollController.offset / 225).clamp(
                              0.0,
                              1.0,
                            ),
                          );
                    return Transform.translate(
                      offset: Offset(0, -(1 - value) * 80),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Logo()
                      .animate(controller: _logoController, autoPlay: false)
                      .effect(
                        delay: const Duration(milliseconds: 800),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutQuad,
                      )
                      .scale(begin: Offset(1.3, 1.3), end: Offset(1.0, 1.0))
                      .slideY(begin: 1.3, end: 0.0)
                      .fadeIn(),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: _LoadingEffect(
            loading: ref.watch(postsProvider.select((p) => p.isLoading)),
            child: ListView.builder(
              controller: _scrollController,
              padding: MediaQuery.paddingOf(context).copyWith(top: 0),
              scrollDirection: Axis.vertical,
              itemCount: posts == null ? 2 : posts.length + 1,
              itemBuilder: (context, indexPlusOne) {
                final halfHeight = MediaQuery.of(context).size.height * 0.5;
                if (indexPlusOne == 0) {
                  return Container(height: halfHeight);
                }

                if (posts == null) {
                  return PostContainer(
                        onTap: null,
                        isFirst: true,
                        child: PostPlaceholderContents(),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: const Duration(seconds: 1),
                        angle: 60 * (pi / 180),
                      );
                }

                final index = indexPlusOne - 1;
                final post = posts[index];
                return PostContainer(
                      key: ValueKey(post.id),
                      onTap: () => _launch(post.url),
                      isFirst: index == 0,
                      isLast: index == posts.length - 1,
                      child: IgnorePointer(
                        child: PostContents(
                          extraTopPadding: index == 0 ? 50 : 0,
                          post: post,
                        ),
                      ),
                    )
                    .animate()
                    .effect(
                      curve: Curves.easeOutQuad,
                      duration: const Duration(milliseconds: 500),
                    )
                    .scale(begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0))
                    .fadeIn();
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: posts == null ? 0.0 : 1.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final value = (1 - _scrollController.offset / 30).clamp(
                    0.0,
                    1.0,
                  );
                  return IgnorePointer(
                    ignoring: value <= 0.0,
                    child: Transform.translate(
                      offset: Offset(0, -(1 - value) * 20),
                      child: Opacity(opacity: value, child: child),
                    ),
                  );
                },
                child: SourcesButton(
                  filter: Set.of(ref.read(postFilterProvider)),
                  onUpdateFilter: (filter) =>
                      ref.read(postFilterProvider.notifier).filter = filter,
                ),
              ),
            ),
          ),
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
    if (await canLaunchUrl(uri)) {
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
