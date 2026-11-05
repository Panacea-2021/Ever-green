import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:evergreen/core/config/environment_config.dart';
import 'package:evergreen/core/network/interceptors/auth_interceptor.dart';
import 'package:evergreen/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _authInterceptorProvider = Provider<AuthInterceptor>(
  (ref) => AuthInterceptor(ref),
);

void main() {
  setUpAll(() => EnvironmentConfig.initialize(Environment.dev));

  test('attaches the stored access token to all announcement endpoints',
      () async {
    final storage = _TestTokenStorage('test.jwt.token');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final adapter = _CaptureAdapter();
    final dio = _client(container.read(_authInterceptorProvider), adapter);
    addTearDown(dio.close);

    final endpoints = [
      ('GET', 'announcements/recipients'),
      ('POST', 'announcements'),
      ('GET', 'announcements/history'),
      ('GET', 'announcements/inbox'),
      ('GET', 'announcements/unread-count'),
      ('POST', 'announcements/41/read'),
    ];
    for (final (method, path) in endpoints) {
      await dio.request<dynamic>(path, options: Options(method: method));
    }

    expect(adapter.requests, hasLength(endpoints.length));
    for (final request in adapter.requests) {
      expect(
        _header(request.headers, 'authorization'),
        'Bear' 'er test.jwt.token',
      );
    }
  });

  test('does not send an Authorization header when no token is stored',
      () async {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(_TestTokenStorage(null)),
      ],
    );
    addTearDown(container.dispose);
    final adapter = _CaptureAdapter();
    final dio = _client(container.read(_authInterceptorProvider), adapter)
      ..options.headers['Authorization'] = 'stale token';
    addTearDown(dio.close);

    await dio.get<dynamic>('announcements/inbox');

    expect(_header(adapter.requests.single.headers, 'authorization'), isNull);
  });

  test('expires the stored session after the backend rejects an expired token',
      () async {
    final storage = _TestTokenStorage('expired.jwt.token');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final adapter = _CaptureAdapter(statusCode: 401);
    final dio = _client(container.read(_authInterceptorProvider), adapter);
    addTearDown(dio.close);

    await expectLater(
      dio.get<dynamic>('announcements/inbox'),
      throwsA(isA<DioException>()),
    );

    expect(storage.expireCalls, 1);
    expect(
      _header(adapter.requests.single.headers, 'authorization'),
      'Bear' 'er expired.jwt.token',
    );
  });
}

Dio _client(AuthInterceptor interceptor, _CaptureAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://backend.example/'))
    ..interceptors.add(interceptor)
    ..httpClientAdapter = adapter;
}

String? _header(Map<String, dynamic> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name) return entry.value?.toString();
  }
  return null;
}

class _TestTokenStorage extends TokenStorage {
  _TestTokenStorage(this.token);

  final String? token;
  int expireCalls = 0;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> expireSession() async {
    expireCalls++;
  }
}

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.statusCode = 200});

  final int statusCode;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"status":200,"data":[]}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
