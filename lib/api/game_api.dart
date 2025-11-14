// lib/api/game_api.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameApi {
  // API 경로
  static const String _gamePath = '/saykorean/game';
  static const String _gameLogPath = '/saykorean/gamelog';

  // JWT 토큰 저장소
  static String? _jwtToken;

  // JWT 토큰 저장
  static Future<void> saveToken(String token) async {
    _jwtToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    print('✅ JWT 토큰 저장 완료');
  }

  // JWT 토큰 로드
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');
    if (_jwtToken != null) {
      print('✅ JWT 토큰 로드 완료');
    }
  }

  // JWT 토큰 삭제 (로그아웃)
  static Future<void> clearToken() async {
    _jwtToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    print(('✅ JWT 토큰 삭제 완료'));
  }

  // 인증 헤더 추가
  static Map<String , dynamic>? _getAuthHeaders() {
    // [JWT 토큰 모드] 토큰이 있으면 Authorization 헤더 추가
    // ⚠️ Spring의 TEST_MODE = false로 전환 시 주석 해제
    // if (_jwtToken != null) {
    //   return {'Authorization': 'Bearer $_jwtToken'};
    // }
    return null;
  }

  // [*] 게임 관련 API

  // [GA-01] 게임 목록 조회 (인증 불필요)


  // [*] 게임 기록 관련 API



  // [GL-01] 게임 기록 생성

  // [GL-02] 내 게임 기록 전체 조회


// [GL-03] 내 게임 기록 상세 조회

}