import 'package:dio/dio.dart';

// 서버 에러 응답 {code, message} 에서 값 꺼내기 (서버 GlobalExceptionHandler 형식)

// 사용자에게 보여줄 서버 사유 — 없으면 null
String? serverErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
  }
  return null;
}

// 에러 코드 (예: "403_001") — 없으면 null
String? serverErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['code'] != null) return data['code'].toString();
  }
  return null;
}
