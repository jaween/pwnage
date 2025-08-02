import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwnage/repositories/posts_repository.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/util.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final posts = ref.watch(postsProvider);
        return switch (posts) {
          AsyncData(:final value) => ColoredBox(
            color: Colors.black,
            child: _Feed(posts: value),
          ),
          AsyncError() => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/jeremy_lol.webp'),
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
          ),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }
}

class _Feed extends StatefulWidget {
  final List<Post> posts;

  const _Feed({super.key, required this.posts});

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  final _scrollController = ScrollController();

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
                  child: Opacity(
                    opacity: value,
                    child: _LogoText()
                        .animate(delay: const Duration(milliseconds: 400))
                        .scale(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuad,
                          begin: Offset(1.3, 1.3),
                          end: Offset(1.0, 1.0),
                        )
                        .fadeIn(),
                  ),
                );
              },
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
                return ClipPath(
                  clipper: _TopCurveClipper(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                  ),
                );
              }
              final index = indexPlusOne - 1;
              final post = widget.posts[index];
              return _PostContainer(
                key: ValueKey(post.id),
                onTap: () => _launch(post.url),
                useRoundedTopCorners: index == 0,
                useRoundedBottomCorners: index == widget.posts.length - 1,
                child: IgnorePointer(
                  child: _PostContents(
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
                    child: Opacity(
                      opacity: value,
                      child: OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            clipBehavior: Clip.hardEdge,
                            isScrollControlled: true,
                            builder: (context) {
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  CheckboxListTile(
                                    value: true,
                                    onChanged: (_) {},
                                    title: Text('Patreon'),
                                  ),
                                  ListTile(title: Text('YouTube')),
                                  ListTile(title: Text('Forum')),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Filters'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText({super.key});

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

class _FeedBackground extends StatefulWidget {
  const _FeedBackground({super.key});

  @override
  State<_FeedBackground> createState() => _FeedBackgroundState();
}

class _FeedBackgroundState extends State<_FeedBackground> {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Image.network(
          'https://scontent-dfw5-1.cdninstagram.com/v/t51.29350-15/514069647_715157874452374_228806038393597263_n.heic?stp=dst-jpg_e35_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6IkNBUk9VU0VMX0lURU0uaW1hZ2VfdXJsZ2VuLjE0NDB4MTE1Mi5zZHIuZjI5MzUwLmRlZmF1bHRfaW1hZ2UuYzIifQ&_nc_ht=scontent-dfw5-1.cdninstagram.com&_nc_cat=110&_nc_oc=Q6cZ2QG-TH5fm4gh0mMxXv81dVcgwpwqHWkBdUuU-iDAEGSaGMAETmiI-WZj3Xwt9dXk5T0&_nc_ohc=Zan_ZUGf-jYQ7kNvwFMvnMf&_nc_gid=Yr75hxyYR1uFK3CXoiucOg&edm=AOmX9WgBAAAA&ccb=7-5&ig_cache_key=MzY2NDM5NTk2NTM1Mzc2NTY1NQ%3D%3D.3-ccb7-5&oh=00_AfSCYn0Tp45RgA4WVZUYPB5qzI38jndWo4MTkXYrwISSkA&oe=6892229D&_nc_sid=bfaa47',
          height: 450,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AnimatedTap extends StatefulWidget {
  final void Function() onTap;
  final Widget child;

  const _AnimatedTap({super.key, required this.onTap, required this.child});

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  Alignment _alignment = Alignment.center;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );
    return GestureDetector(
      onTapDown: (details) {
        final size = context.size ?? const Size(1, 1);
        final x = details.localPosition.dx / size.width;
        final y = details.localPosition.dy / size.height;
        setState(() => _alignment = Alignment(x * 2 - 1, y * 2 - 1));
        _animationController.forward(from: 0.0);
      },
      onTapCancel: _animationController.reverse,
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, child) {
          return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(curvedAnimation.value * 24),
                  ),
                ),
                child: widget.child,
              )
              .animate(controller: _animationController, autoPlay: false)
              .scale(
                begin: Offset(1.0, 1.0),
                end: Offset(0.95, 0.95),
                curve: Curves.easeOutQuad,
                alignment: _alignment,
              );
        },
      ),
    );
  }
}

class _PostContainer extends StatelessWidget {
  final VoidCallback onTap;
  final bool useRoundedTopCorners;
  final bool useRoundedBottomCorners;
  final Widget child;
  const _PostContainer({
    super.key,
    required this.onTap,
    this.useRoundedTopCorners = false,
    this.useRoundedBottomCorners = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomBorderRadius = !useRoundedBottomCorners
        ? BorderRadius.zero
        : const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          );
    final borderRadius = bottomBorderRadius;
    return _AnimatedTap(
      onTap: onTap,
      child: ClipPath(
        clipper: useRoundedTopCorners ? _TopCurveClipper() : _NoneClipper(),
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: borderRadius,
          child: Container(
            constraints: BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: borderRadius,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border(
                top: BorderSide(color: Colors.white.withAlpha(50)),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

String prepareHtml(String html) {
  final trimmed = html.trim();

  // Check if it contains any HTML tags
  final hasTags = RegExp(r'<[^>]+>').hasMatch(trimmed);

  if (!hasTags) {
    // Wrap plain text in a paragraph
    return '<p>$html</p>';
  }

  return html;
}

class _PostContents extends StatelessWidget {
  final double extraTopPadding;
  final Post post;
  const _PostContents({
    super.key,
    this.extraTopPadding = 0,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final data = post.data;
    ({String title, String? summary, String? image}) fields = switch (data) {
      YoutubeVideo() => (
        title: data.title,
        summary: data.description,
        image: data.thumbnailUrl,
      ),
      ForumThread() => (title: data.title, summary: data.content, image: null),
      PatreonPost() => (
        title: data.title,
        summary: data.teaserText ?? '',
        image: data.imageUrl,
      ),
      _ => (title: '', summary: null, image: null),
    };

    final image = fields.image;
    return IntrinsicHeight(
      child: Stack(
        children: [
          if (image != null)
            SizedBox(
              height: 550,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Normal image
                  Transform.scale(
                    scale: 1.05,
                    child: Image.network(image, fit: BoxFit.cover),
                  ),
                  // Image that starts blurred and gradually unblurs
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.transparent],
                        stops: [0.0, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      // Scaling image to deal with edges looking bad when blurred
                      child: Transform.scale(
                        scale: 1.05,
                        child: Image.network(image, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(150), Colors.transparent],
                  stops: [0.3, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: extraTopPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _PostSource(
                        postDataType: data.type,
                        publishedAt: post.publishedAt,
                        avatarUrl: post.author.avatarUrl,
                        authorName: post.author.name,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        fields.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.interTightTextTheme(
                              TextTheme.of(context),
                            ).headlineMedium?.copyWith(
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 15,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Html(
                          data: fields.summary ?? '',
                          doNotRenderTheseTags: {'hr'},
                          style: {
                            'body': Style(
                              padding: HtmlPaddings.only(bottom: 8),
                              fontSize: FontSize(14),
                              fontWeight: FontWeight.w900,
                              maxLines: 6,
                              textOverflow: TextOverflow.ellipsis,
                              textShadow: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 15,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({super.key, required this.child, required this.onChange});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final _key = GlobalKey();
  Size? oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    return Container(key: _key, child: widget.child);
  }

  void _notifySize() {
    final context = _key.currentContext;
    if (context == null) return;

    final newSize = context.size;
    if (newSize != null && oldSize != newSize) {
      oldSize = newSize;
      widget.onChange(newSize);
    }
  }
}

class FadeIfOverflow extends StatefulWidget {
  final double maxHeight;
  final Widget child;

  const FadeIfOverflow({
    super.key,
    required this.maxHeight,
    required this.child,
  });

  @override
  State<FadeIfOverflow> createState() => _FadeIfOverflowState();
}

class _FadeIfOverflowState extends State<FadeIfOverflow> {
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Stack(
        children: [
          MeasureSize(
            onChange: (size) {
              final didOverflow = size.height > widget.maxHeight;
              if (didOverflow != _isOverflowing) {
                setState(() => _isOverflowing = didOverflow);
              }
            },
            child: widget.child,
          ),
          if (_isOverflowing)
            Positioned.fill(
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.7, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostSource extends StatelessWidget {
  final PostDataType postDataType;
  final DateTime publishedAt;
  final String avatarUrl;
  final String authorName;

  const _PostSource({
    super.key,
    required this.postDataType,
    required this.publishedAt,
    required this.avatarUrl,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextTheme.of(context).labelMedium!.copyWith(
        color: Colors.white54,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 0)),
        ],
      ),
      child: Row(
        children: [
          _PlatformBadge(type: postDataType),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 4),
                Text(formatDateTime(publishedAt)),
                Text(authorName),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.pink,
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.black, Colors.transparent],
                stops: [0.0, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  spreadRadius: 2,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, s) {
                return Icon(Icons.account_circle);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final PostDataType type;

  const _PlatformBadge({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 16,
            child: switch (type) {
              PostDataType.youtubeVideo => SvgPicture.asset(
                'assets/icons/youtube_logo.svg',
                colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
              ),
              PostDataType.forumThread => Icon(
                Icons.forum,
                size: 20,
                color: Colors.white54,
              ),
              PostDataType.patreonPost => SvgPicture.asset(
                'assets/icons/patreon_logo.svg',
                colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
              ),
            },
          ),
          const SizedBox(width: 12),
          Text(switch (type) {
            PostDataType.youtubeVideo => 'YouTube',
            PostDataType.forumThread => 'Forum',
            PostDataType.patreonPost => 'Patreon',
          }),
        ],
      ),
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const curveHeight = 50.0;

    path.lineTo(0, curveHeight);
    path.quadraticBezierTo(size.width / 2, 0, size.width, curveHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class _NoneClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Offset.zero & size);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

void _launch(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
