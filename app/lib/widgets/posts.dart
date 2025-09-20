import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/util.dart';
import 'package:pwnage/widgets/image.dart';
import 'package:pwnage/widgets/sources.dart';

class PostContainer extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const PostContainer({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: BoxConstraints(maxHeight: 600),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: Colors.white.withAlpha(50)),
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PostContents extends StatelessWidget {
  final Post post;
  const PostContents({super.key, required this.post});

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
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withAlpha(50)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              style: GoogleFonts.interTightTextTheme(TextTheme.of(context))
                  .headlineMedium
                  ?.copyWith(
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
          Padding(
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
          if (image != null)
            Flexible(child: FadeInNetworkImage(image, fit: BoxFit.cover)),
        ],
      ),
    );
  }
}

class PostPlaceholderContents extends StatelessWidget {
  const PostPlaceholderContents({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 70,
            width: 100,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 70,
            height: 32,
            child: Row(
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 70 + 16 + 32,
            right: 16,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 70 + 16 + 32 + 16 + 48,
            right: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  spreadRadius: 2,
                  blurRadius: 2,
                ),
              ],
            ),
            child: FadeInNetworkImage(avatarUrl, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
