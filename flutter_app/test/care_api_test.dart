import 'dart:convert';

import 'package:care_today_mobile/data/care_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CareApi', () {
    test(
        'Given a successful response, when list is called, then JSON is returned',
        () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response('[{"id":"space-1"}]', 200);
      });
      final api = CareApi(baseUrl: 'https://example.test/api', client: client)
        ..token = 'test-token';

      final result = await api.list('/spaces');

      expect(result.single['id'], 'space-1');
    });

    test(
        'Given an API error, when request is called, then ApiException contains reason',
        () async {
      final api = CareApi(
          client: MockClient((_) async =>
              http.Response.bytes(utf8.encode('{"reason":"登录已过期"}'), 401)));

      expect(
          () => api.list('/spaces'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', '登录已过期')));
    });
  });
}
