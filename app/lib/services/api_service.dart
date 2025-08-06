import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service.freezed.dart';
part 'api_service.g.dart';

const _kTimeout = Duration(seconds: 10);

@riverpod
ApiService apiService(Ref ref) => throw 'Uninitialized provider';

class ApiService {
  final String baseUrl;
  final Map<String, String> _headers;
  late final http.Client _client;

  ApiService({required this.baseUrl})
    : _headers = {
        'accept': 'application/json',
        'x-app-platform': _appPlatform,
      } {
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }

  Future<Either<Error, PostResponse>> getPosts({
    DateTime? before,
    int limit = 10,
    Set<PostDataType>? filter,
  }) {
    final queryParams = [
      'before=${(before ?? DateTime.now().toUtc()).toIso8601String()}',
      'limit=$limit',
      if (filter != null) 'filter=${filter.map((f) => f.queryKey).join(',')}',
    ].join('&');
    return _makeRequest(
      request: () => _client.get(
        Uri.parse('$baseUrl/v1/posts?$queryParams'),
        headers: _headers,
      ),
      handleResponse: (response) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return right(PostResponse.fromJson(body));
      },
    );
  }
}

Future<Either<Error, R>> _makeRequest<T, R>({
  required Future<http.Response> Function() request,
  required Either<Error, R> Function(http.Response response) handleResponse,
  Error Function(http.Response response)? handleError,
}) async {
  try {
    final response = await request().timeout(_kTimeout);
    if (response.statusCode != 200) {
      if (response.statusCode == 400 && handleError != null) {
        return left(handleError(response));
      } else if (response.statusCode == 500) {
        return left('ServerError');
      } else {
        return left('UnhandledError(${response.statusCode})');
      }
    }
    return handleResponse(response);
  } on http.ClientException {
    return left('PackageError');
  } on SocketException {
    return left('NetworkError');
  } on TimeoutException {
    return left('NetworkError');
  } catch (e, s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
    return left('UnhandledError(${e.toString()})');
  }
}

String get _appPlatform {
  if (kIsWeb || kIsWasm) {
    return 'web';
  } else if (Platform.isIOS) {
    return 'ios';
  } else if (Platform.isAndroid) {
    return 'android';
  }
  return 'web';
}

@freezed
abstract class PostResponse with _$PostResponse {
  const factory PostResponse({
    required List<Post> posts,
    required bool hasMore,
  }) = _PostResponse;

  factory PostResponse.fromJson(Map<String, dynamic> json) =>
      _$PostResponseFromJson(json);
}

enum PostDataType {
  youtubeVideo(queryKey: 'youtube', label: 'YouTube'),
  forumThread(queryKey: 'forum', label: 'Forum'),
  patreonPost(queryKey: 'patreon', label: 'Patreon');

  final String queryKey;
  final String label;

  const PostDataType({required this.queryKey, required this.label});
}

@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    @DateTimeConverter() required DateTime publishedAt,
    @DateTimeConverter() required DateTime updatedAt,
    required String url,
    required PostAuthor author,
    required PostData data,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
abstract class PostAuthor with _$PostAuthor {
  const factory PostAuthor({required String name, required String avatarUrl}) =
      _PostAuthor;

  factory PostAuthor.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorFromJson(json);
}

@Freezed(unionKey: 'type')
abstract class PostData with _$PostData {
  const factory PostData.youtubeVideo({
    required String id,
    required PostDataType type,
    required String url,
    @DateTimeConverter() required DateTime publishedAt,
    @DateTimeConverter() required DateTime? updatedAt,
    required String title,
    required String description,
    required String thumbnailUrl,
  }) = YoutubeVideo;

  const factory PostData.forumThread({
    required String id,
    required PostDataType type,
    required String url,
    @DateTimeConverter() required DateTime publishedAt,
    @DateTimeConverter() required DateTime updatedAt,
    required String title,
    required String content,
  }) = ForumThread;

  const factory PostData.patreonPost({
    required String id,
    required PostDataType type,
    required String url,
    @DateTimeConverter() required DateTime publishedAt,
    required String title,
    required String? teaserText,
    required String? imageUrl,
  }) = PatreonPost;

  factory PostData.fromJson(Map<String, dynamic> json) =>
      _$PostDataFromJson(json);
}

class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String value) => DateTime.parse(value);

  @override
  String toJson(DateTime dateTime) => dateTime.toUtc().toIso8601String();
}

typedef Error = String;

sealed class Either<L, R> {
  const Either();
}

final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}

Either<L, R> left<L, R>(L value) => Left<L, R>(value);
Either<L, R> right<L, R>(R value) => Right<L, R>(value);
