import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pwnage/repositories/posts_repository.dart';
import 'package:pwnage/services/api_service.dart';

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
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final data = post.data;
        return switch (data) {
          YoutubeVideo() => ListTile(
            onTap: () => launch(data.url),
            title: Text(data.title),
          ),
          ForumThread() => ListTile(
            onTap: () => launch(data.url),
            title: Text(data.title),
          ),
          PatreonPost() => ListTile(
            onTap: () => launch(data.url),
            title: Text(data.teaserText),
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  void launch(String url) async {
    final uri = Uri.parse(url);
    // TODO: Launch URL
  }
}
