// lib/api/game_api.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameApi {
  // [*] Dio 임포트
  static final Dio _dio = ApiClient.dio;

  static const String _gamePath = '/saykorean/game';
  static const String _gameLogPath = '/saykorean/gamelog';

  // JWT 토큰 저장소
  // static String? _jwtToken;
  
  // [*] JWT 토큰 관리

  // JWT 토큰 저장
  // static Future<void> saveToken(String token) async {
  //   _jwtToken = token;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('jwt_token', token);
  //   print('✅ JWT 토큰 저장 완료');
  // }

  // JWT 토큰 로드
  // static Future<void> loadToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _jwtToken = prefs.getString('jwt_token');
  //   if (_jwtToken != null) {
  //     print('✅ JWT 토큰 로드 완료');
  //   }
  // }

  // JWT 토큰 삭제 (로그아웃)
  // static Future<void> clearToken() async {
  //   _jwtToken = null;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('jwt_token');
  //   print(('✅ JWT 토큰 삭제 완료'));
  // }

  // 인증 헤더 추가
  static Map<String , dynamic> _getAuthHeaders() {
    // [테스트 모드] 기본 헤더만 반환
    Map<String, dynamic> headers = {
      'X-Client-Type' : 'flutter' ,
      'Content-Type' : 'application/json' ,
    };
    
    // [JWT 토큰 모드] 토큰이 있으면 Authorization 헤더 추가
    // ⚠️ Spring의 TEST_MODE = false로 전환 시 주석 해제
    // ✅ 토큰이 있으면 기존 헤더에 추가
    // if (_jwtToken != null) {
    //   headers['Authorization'] = 'Bearer $_jwtToken';
    // }
    return headers;
  }

  // [*] 게임 관련 API

  // [GA-01] 게임 목록 조회 (인증 불필요)
  static Future<List<dynamic>> getGameList() async {
    try{
      final res = await _dio.get(
        _gamePath,
        options: Options(
          headers: {'X-Client-Type' : 'flutter'},
        ),
      );
      
      print('✅ 게임 목록 조회 성공: ${res.data}');
      return res.data as List<dynamic>;
    } catch (e) {
      print("❌ 게임 목록 조회 실패: $e");
      rethrow;
    }
  }

  // [*] 게임 기록 관련 API

  // [GL-01] 게임 기록 생성
  static Future<Map<String, dynamic>> createGameLog({
    required int gameNo,
    required int gameResult,
    required int gameScore,
}) async {
    try {
      // 테스트 모드에서는 토큰 로드 불필요
      // [JWT 모드 전환 시] 주석 해제할 것!
      // await loadToken();
      
      final res = await _dio.post(
        _gameLogPath,
        data: {
          'gameNo' : gameNo,
          'gameResult' : gameResult,
          'gameScore' : gameScore,
        },
        options: Options(headers: _getAuthHeaders()),
      );
      
      print('✅ 게임 기록 생성 성공: ${res.data}');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ 게임 기록 생성 실패: $e');
      rethrow;
    }
  }

  // [GL-02] 내 게임 기록 전체 조회
  static Future<List<dynamic>> getMyGameLog() async {
    try {
      // 테스트 모드에서는 토큰 로드 불필요
      // [JWT 모드 전환 시] 주석 해제
      // await loadToken();
      
      final res = await _dio.get(
        _gameLogPath,
        options: Options(headers: _getAuthHeaders()),
      );
      
      print('✅ 내 게임 기록 조회 성공: ${res.data}');
      return res.data as List<dynamic>;
    } catch (e) {
      print("❌ 내 게임 기록 조회 실패: $e");
      rethrow;
    }
  }


  // [GL-03] 내 게임 기록 상세 조회
  static Future<Map<String, dynamic>> getMyGameLogDetail(int gameLogNo) async {
    try {
      // 테스트 모드에서는 토큰 로드 불필요
      // [JWT 모드 전환 시] 주석 해제
      // await loadToken();

      final res = await _dio.get(
        '$_gameLogPath/detail',
        queryParameters: {'gameLogNo' : gameLogNo},
        options: Options(headers: _getAuthHeaders()),
      );
      
      print('✅ 게임 기록 상세 조회 성공: ${res.data}');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ 게임 기록 상세 조회 실패: $e');
      rethrow;
    }
  }

}
