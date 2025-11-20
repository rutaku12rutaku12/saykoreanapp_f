// lib/api.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // [*] 환경별 BaseURL 자동감지
  static String _detectBaseUrl() {
    // 1. 환경변수 우선 (배포 시 사용)
    const env = String.fromEnvironment('API_HOST');
    if (env.isNotEmpty) return env;

    // 2. 플랫폼별 기본값
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';  // 에뮬레이터 (안드로이드)
    if (Platform.isIOS) return 'http://localhost:8080';     // 시뮬레이터 (IOS)

    return 'http://localhost:8080';                         // 디폴트
  }

  // WebSocket용 URL 자동 분기 추가
  static String detectWsUrl(){
    final env = const String.fromEnvironment('API_HOST');
    if(env.isNotEmpty){
      return env.replaceFirst("http", "ws") + "/ws/chat";
    }
    if(kIsWeb){
      return 'ws://localhost:8080/ws/chat';
    }
    if(Platform.isAndroid){
      return 'ws://10.0.2.2:8080/ws/chat';
    }
    return 'ws://localhost:8080/ws/chat';
  }

  // [*] Dio 인스턴스 (싱글톤)
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _detectBaseUrl(),
      connectTimeout: const Duration(seconds: 10),  // 6 -> 10초
      receiveTimeout: const Duration(seconds: 15),  // 12 -> 15초
      headers: {
        'X-Client-Type': 'flutter',
        'Content-Type': 'application/json'
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options,handler) async{
        // JWT 토큰 자동 추가
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if( token != null && token.isNotEmpty ){
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ Authorization 헤더 추가');
        }

        print('🌐 요청: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response,handler){
        print('✅ 응답 성공: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API 에러: ${error.response?.statusCode}');
        print('   URL: ${error.requestOptions.uri}');
        print('   메시지: ${error.response?.data}');
        return handler.next(error);
      }
    ),
  );

  // [*] Base URI (URL 생성용)
  static final Uri _baseUri = Uri.parse(_detectBaseUrl());

  // [*] 일반 URL 생성 (API 엔드포인트용)
  static String buildUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // 이미 완전한 URL이면 그대로 반환
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    // file:// 프로토콜 처리 (로컬 파일)
    if (path.startsWith('file://')) {
      final p = path.replaceFirst('file://', '');
      return _baseUri.resolve(p.startsWith('/') ? p.substring(1) : p).toString();
    }

    // 상대 경로를 절대 URL로 변환
    return _baseUri
        .resolve(path.startsWith('/') ? path.substring(1) : path)
        .toString();
  }

  // ✅ 이미지 URL 생성 (Spring의 /upload/** 경로)
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';  // 빈 문자열 반환 -> 에러 위젯 표시
    }

    // 이미 완전한 URL이면 그대로 반환
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // /upload로 시작하면 baseUrl과 결합
    if (imagePath.startsWith('/upload')) {
      return '${_detectBaseUrl()}$imagePath';
    }

    // upload로 시작하면 / 추가
    if (imagePath.startsWith('upload')) {
      return '${_detectBaseUrl()}/$imagePath';
    }

    // 기타 경로는 /upload/ 추가
    return '${_detectBaseUrl()}/upload/$imagePath';
  }

  // ✅ 오디오 URL 생성 (이미지와 동일한 로직)
  static String getAudioUrl(String? audioPath) {
    if (audioPath == null || audioPath.isEmpty) {
      return '';
    }

    if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
      return audioPath;
    }

    if (audioPath.startsWith('/upload')) {
      return '${_detectBaseUrl()}$audioPath';
    }

    if (audioPath.startsWith('upload')) {
      return '${_detectBaseUrl()}/$audioPath';
    }

    return '${_detectBaseUrl()}/upload/$audioPath';
  }

  // ✅ URL 유효성 검사
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // ✅ Base URL 확인용 (디버깅)
  static String getBaseUrl() {
    return _detectBaseUrl();
  }

  // ✅ 토큰 저장

  // ✅ 토큰 삭제 (로그아웃)

  // ✅ 토큰 확인

}
