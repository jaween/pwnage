import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pwnage/repositories/posts_repository.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:pwnage/util.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final posts = ref.watch(postsProvider);
          return switch (posts) {
            AsyncData(:final value) => _Feed(posts: value),
            AsyncError() => const Center(child: Text('Something went wrong')),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  final List<Post> posts;

  const _Feed({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Image.network(
            'https://scontent-dfw5-1.cdninstagram.com/v/t51.29350-15/514069647_715157874452374_228806038393597263_n.heic?stp=dst-jpg_e35_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6IkNBUk9VU0VMX0lURU0uaW1hZ2VfdXJsZ2VuLjE0NDB4MTE1Mi5zZHIuZjI5MzUwLmRlZmF1bHRfaW1hZ2UuYzIifQ&_nc_ht=scontent-dfw5-1.cdninstagram.com&_nc_cat=110&_nc_oc=Q6cZ2QG-TH5fm4gh0mMxXv81dVcgwpwqHWkBdUuU-iDAEGSaGMAETmiI-WZj3Xwt9dXk5T0&_nc_ohc=Zan_ZUGf-jYQ7kNvwFMvnMf&_nc_gid=Yr75hxyYR1uFK3CXoiucOg&edm=AOmX9WgBAAAA&ccb=7-5&ig_cache_key=MzY2NDM5NTk2NTM1Mzc2NTY1NQ%3D%3D.3-ccb7-5&oh=00_AfSCYn0Tp45RgA4WVZUYPB5qzI38jndWo4MTkXYrwISSkA&oe=6892229D&_nc_sid=bfaa47',
            height: 450,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: ListView.builder(
            padding: MediaQuery.of(context).padding + EdgeInsets.only(top: 250),
            itemCount: posts.length + 1,
            itemBuilder: (context, indexPlusOne) {
              if (indexPlusOne == 0) {
                return ClipPath(
                  clipper: TopCurveClipper(),
                  child: Container(
                    height: 100,
                    color: Theme.of(context).cardColor,
                  ),
                );
              }
              final index = indexPlusOne - 1;
              final post = posts[index];
              return Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: _PostContainer(
                  onTap: () => _launch(post.url),
                  child: _PostContents(post: post),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostContainer extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PostContainer({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
              blurRadius: 4,
              spreadRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PostContents extends StatelessWidget {
  final Post post;
  const _PostContents({super.key, required this.post});

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
        title: data.teaserText ?? '',
        summary: null,
        image: null,
      ),
      _ => (title: '', summary: null, image: null),
    };

    final image = fields.image;
    return Column(
      children: [
        if (image != null) Image.network(image),
        _PostFooter(
          postDataType: data.type,
          publishedAt: post.publishedAt,
          title: fields.title,
          summary: fields.summary ?? '',
          avatarUrl: '',
          authorName: 'teh_pwnerer',
        ),
      ],
    );
  }
}

class _PostFooter extends StatelessWidget {
  final PostDataType postDataType;
  final DateTime publishedAt;
  final String title;
  final String summary;
  final String avatarUrl;
  final String authorName;

  const _PostFooter({
    super.key,
    required this.postDataType,
    required this.publishedAt,
    required this.title,
    required this.summary,
    required this.avatarUrl,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 26),
              ),
              Text(
                summary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          SizedBox(
            child: Row(
              children: [
                ClipRRect(
                  child: Container(
                    color: Theme.of(context).cardColor,
                    // child: Image.network(avatarUrl),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(authorName),
                      Row(
                        children: [
                          Expanded(child: Text(formatDateTime(publishedAt))),
                          _PlatformBadge(type: postDataType),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    final color = switch (type) {
      PostDataType.youtubeVideo => Colors.red,
      PostDataType.forumThread => Colors.orange,
      PostDataType.patreonPost => Colors.black,
    };
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Text(switch (type) {
        PostDataType.youtubeVideo => 'YouTube',
        PostDataType.forumThread => 'Forum',
        PostDataType.patreonPost => 'Patreon',
      }, style: TextStyle(color: color)),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const curveHeight = 80.0;

    path.lineTo(0, curveHeight);
    path.quadraticBezierTo(size.width / 2, 0, size.width, curveHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

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
