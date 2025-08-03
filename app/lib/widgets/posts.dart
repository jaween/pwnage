import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/util.dart';
import 'package:pwnage/widgets/image.dart';
import 'package:pwnage/widgets/sources.dart';

class PostContainer extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const PostContainer({
    super.key,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = !isLast
        ? BorderRadius.zero
        : const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          );
    return _AnimatedTap(
      onTap: onTap,
      child: ClipPath(
        clipper: isFirst ? _TopCurveClipper() : _NoClipClipper(),
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

class PostContents extends StatelessWidget {
  final double extraTopPadding;
  final Post post;
  const PostContents({super.key, this.extraTopPadding = 0, required this.post});

  @override
  Widget build(BuildContext context) {
    final data = post.data;
    ({String? summary, String? image}) fields = switch (data) {
      YoutubeVideo() => (summary: data.description, image: data.thumbnailUrl),
      ForumThread() => (summary: data.content, image: null),
      PatreonPost() => (summary: data.teaserText ?? '', image: data.imageUrl),
      _ => (summary: null, image: null),
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
                    child: FadeInNetworkImage(image, fit: BoxFit.cover),
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
                        child: FadeInNetworkImage(image, fit: BoxFit.cover),
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
                      child: _Metadata(
                        postDataType: data.type,
                        publishedAt: post.publishedAt,
                        avatarUrl: post.author.avatarUrl,
                        authorName: post.author.name,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        data.title,
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

class _AnimatedTap extends StatefulWidget {
  final void Function()? onTap;
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
      onTapDown: widget.onTap == null
          ? null
          : (details) {
              final size = context.size ?? const Size(1, 1);
              final x = details.localPosition.dx / size.width;
              final y = details.localPosition.dy / size.height;
              setState(() => _alignment = Alignment(x * 2 - 1, y * 2 - 1));
              _animationController.forward(from: 0.0);
            },
      onTapCancel: widget.onTap == null ? null : _animationController.reverse,
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _animationController.reverse();
              widget.onTap?.call();
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

class _Metadata extends StatelessWidget {
  final PostDataType postDataType;
  final DateTime publishedAt;
  final String avatarUrl;
  final String authorName;

  const _Metadata({
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
          SourceBadge(type: postDataType),
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

class _NoClipClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Offset.zero & size);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
