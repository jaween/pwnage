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

  @override
  void initState() {
    super.initState();
    ref.listenManual(postsProvider, (prev, next) {
      final value = next.valueOrNull;
      if (value != null) {
        setState(() => _posts = value.posts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Uses cached state so we don't show reload on filter change
    final cachedPosts = _posts;
    if (cachedPosts != null) {
      return _Feed(posts: cachedPosts);
    }

    final posts = ref.watch(postsProvider);
    return switch (posts) {
      AsyncData() => ColoredBox(
        color: Colors.black,
        // Should not be possible to reach this
        child: const SizedBox.shrink(),
      ),
      AsyncError() => _SomethingWentWrong(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Feed extends ConsumerStatefulWidget {
  final List<Post> posts;

  const _Feed({super.key, required this.posts});

  @override
  ConsumerState<_Feed> createState() => _FeedState();
}

class _FeedState extends ConsumerState<_Feed> {
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
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.sizeOf(context).height / 4 - 60,
            ),
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final value = !_scrollController.hasClients
                    ? 1.0
                    : Curves.easeOutCubic.transform(
                        (1 - _scrollController.offset / 225).clamp(0.0, 1.0),
                      );
                return Transform.translate(
                  offset: Offset(0, -(1 - value) * 80),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Logo()
                  .animate(delay: const Duration(milliseconds: 400))
                  .scale(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuad,
                    begin: Offset(1.3, 1.3),
                    end: Offset(1.0, 1.0),
                  )
                  .fadeIn(),
            ),
          ),
        ),
        Positioned.fill(
          child: ListView.builder(
            controller: _scrollController,
            padding:
                MediaQuery.paddingOf(context).copyWith(top: 0) +
                EdgeInsets.only(bottom: 88),
            scrollDirection: Axis.vertical,
            itemCount: widget.posts.length + 1,
            itemBuilder: (context, indexPlusOne) {
              if (indexPlusOne == 0) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                );
              }
              final index = indexPlusOne - 1;
              final post = widget.posts[index];
              return PostContainer(
                key: ValueKey(post.id),
                onTap: () => _launch(post.url),
                isFirst: index == 0,
                isLast: index == widget.posts.length - 1,
                child: IgnorePointer(
                  child: PostContents(
                    extraTopPadding: index == 0 ? 50 : 0,
                    post: post,
                  ),
                ),
              ).animate().scale(
                begin: Offset(1.1, 1.1),
                end: Offset(1, 1),
                curve: Curves.easeOutQuad,
                duration: const Duration(milliseconds: 300),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.center,
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
