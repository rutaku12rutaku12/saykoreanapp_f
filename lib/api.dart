// lib/common/api_client.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String _detectBaseUrl() {
    final env = const String.fromEnvironment('API_HOST');
    if (env.isNotEmpty) return env;

    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _detectBaseUrl(),
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'X-Client-Type': 'flutter',
        'Content-Type': 'application/json'
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options,handler) async{
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if( token != null && token.isNotEmpty ){
          options.headers['Authorization'] = 'Bearer $token';
          print('Authorization 헤더 추가');
        }
        return handler.next(options);
      },
      onResponse: (response,handler){
        print('응답성공: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('API 에러: ${error.response?.statusCode}');
        print('URL: ${error.requestOptions.uri}');
        print('메시지: ${error.response?.data}');
        return handler.next(error);
      }
    ),
  );

  static final Uri _baseUri = Uri.parse(_detectBaseUrl());

  static String buildUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('file://')) {
      final p = path.replaceFirst('file://', '');
      return _baseUri.resolve(p.startsWith('/') ? p.substring(1) : p).toString();
    }
    return _baseUri
        .resolve(path.startsWith('/') ? path.substring(1) : path)
        .toString();
  }
}
