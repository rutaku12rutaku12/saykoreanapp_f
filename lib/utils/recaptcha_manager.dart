import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import 'package:flutter/foundation.dart';

// reCAPTCHA Enterprise Client를 앱 전체에서 관리하기 위한 정적 유틸리티 클래스입니다.
class RecaptchaManager {
  // 널러블 정적 클라이언트 인스턴스를 저장합니다.
  static RecaptchaClient? _client;

  // reCAPTCHA 클라이언트 인스턴스를 설정하는 메서드입니다.
  static void setClient(RecaptchaClient client) {
    if (_client != null) {
      debugPrint("RecaptchaManager: Client already set. Overwriting.");
    }
    _client = client;
  }

  // reCAPTCHA 클라이언트 인스턴스를 가져오는 메서드입니다.
  // 클라이언트가 설정되지 않았다면 (예: 초기화 실패) 예외를 발생시킵니다.
  static RecaptchaClient getClient() {
    if (_client == null) {
      throw Exception("Recaptcha client is not initialized. Check main.dart setup.");
    }
    return _client!;
  }
}