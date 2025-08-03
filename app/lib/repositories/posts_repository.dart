import 'package:collection/collection.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posts_repository.g.dart';

@riverpod
class PostFilter extends _$PostFilter {
  @override
  Set<PostDataType> build() => PostDataType.values.toSet();

  set filter(Set<PostDataType> filter) {
    final deepEquals = const DeepCollectionEquality().equals;
    if (!deepEquals(filter, state) && filter.isNotEmpty) {
      state = Set.of(filter);
    }
  }
}

@riverpod
class Posts extends _$Posts {
  @override
  Future<List<Post>> build() async {
    final api = ref.watch(apiServiceProvider);
    final filter = ref.watch(postFilterProvider);
    final posts = await api.getPosts(limit: 10, filter: filter);
    switch (posts) {
      case Left(:final value):
        throw value;
      case Right(:final value):
        return value;
    }
  }
}
