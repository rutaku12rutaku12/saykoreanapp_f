import 'dart:io' show Platform;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:saykoreanapp_f/api/base_url.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio dio;
  bool _isInitialized = false;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    if ( kIsWeb ) {
      // 웹 환경
      print("웹 환경 - 쿠키 자동 처리");
      dio= Dio(
        BaseOptions(
          baseUrl: baseUrl,
          validateStatus: (status) => status! < 500,
          // 웹에서는 브라우저가 자동으로 쿠키 처리
        ),
      );
    } else{
      // 모바일 앱 환경
      print("모바일 앱 환경");
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage("${appDocDir.path}/.cookies/"),
      );

      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          validateStatus: (status) => status! < 500,
        ),
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }

    _isInitialized = true;
  }

  Dio get instance => dio;
}