import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../core/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class CareApi {
  CareApi({this.baseUrl = careApiBase, http.Client? client})
      : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  String? token;

  Future<dynamic> request(String path,
      {String method = 'GET', Object? body}) async {
    final response =
        await _client.send(http.Request(method, Uri.parse('$baseUrl$path'))
          ..headers.addAll({
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          })
          ..body = body == null ? '' : jsonEncode(body));
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map ? decoded['reason'] ?? decoded['message'] : null;
      throw ApiException(message?.toString() ?? '请求失败（${response.statusCode}）',
          response.statusCode);
    }
    return decoded;
  }

  /// 上传一张图片，返回 {id, url}。
  Future<Map<String, dynamic>> uploadPhoto(String spaceId, String filename,
      List<int> bytes, String contentType) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/spaces/$spaceId/files'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename,
          contentType: http_parser.MediaType.parse(contentType)));
    final response = await _client.send(request);
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map ? decoded['reason'] ?? decoded['message'] : null;
      throw ApiException(message?.toString() ?? '上传失败（${response.statusCode}）',
          response.statusCode);
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          await request('/auth/login', method: 'POST', body: body));
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          await request('/auth/register', method: 'POST', body: body));
  Future<List<dynamic>> list(String path) async =>
      List<dynamic>.from(await request(path) ?? const []);
  Future<Map<String, dynamic>> object(String path) async =>
      Map<String, dynamic>.from(await request(path));
}
