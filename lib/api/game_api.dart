// lib/api/game_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameApi {
  // .env에서 BASE_URL 읽기
  static String get baseURL => dotenv.env['BASE_URL'] ?? 'http://localhost:8080';
  static const String apiPath = '/saykorean';

  // 세션 쿠키 저장소
  static String? _sessionCookie;

// 로그인 후 세션 쿠키를 저장하는 메소드
// static Future<void> saveSessionCookie(String cookie) async {
//   _sessionCookie = cookie;
//   final prefs = await SharedPreferences.getInstance();
//   await prefs = setString('session_cookie' , cookie);
//
// }

}