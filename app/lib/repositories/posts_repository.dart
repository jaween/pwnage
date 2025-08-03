import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pwnage/services/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posts_repository.freezed.dart';
part 'posts_repository.g.dart';

@freezed
abstract class PostsState with _$PostsState {
  const factory PostsState({
    @Default([]) List<Post> posts,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
  }) = _PostsState;
}

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
  Future<PostsState> build() async {
    // TODO: This builds twice initially, why?
    final api = ref.watch(apiServiceProvider);
    final filter = ref.watch(postFilterProvider);
    final result = await api.getPosts(limit: 10, filter: filter);
    return switch (result) {
      Left(:final value) => throw value,
      Right(:final value) => PostsState(
        posts: value.posts,
        isLoadingMore: false,
        hasMore: value.hasMore,
      ),
    };
  }

  Future<void> loadMore() async {
    final api = ref.read(apiServiceProvider);
    final filter = ref.read(postFilterProvider);
    final stateVal = state.valueOrNull;

    if (stateVal == null || stateVal.isLoadingMore || !stateVal.hasMore) {
      return;
    }

    state = AsyncValue.data(stateVal.copyWith(isLoadingMore: true));

    final result = await api.getPosts(
      limit: 10,
      before: stateVal.posts.last.publishedAt,
      filter: filter,
    );

    switch (result) {
      case Left(:final value):
        state = AsyncValue.error(value, StackTrace.current);
      case Right(:final value):
        state = AsyncValue.data(
          PostsState(
            posts: [...stateVal.posts, ...value.posts],
            hasMore: value.hasMore,
            isLoadingMore: false,
          ),
        );
    }
  }
}
