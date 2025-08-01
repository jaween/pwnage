import 'package:pwnage/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posts_repository.g.dart';

@riverpod
class Posts extends _$Posts {
  @override
  Future<List<Post>> build() async {
    final api = ref.watch(apiServiceProvider);
    final posts = await api.getPosts();
    switch (posts) {
      case Left(:final value):
        throw value;
      case Right(:final value):
        return value;
    }
  }
}
