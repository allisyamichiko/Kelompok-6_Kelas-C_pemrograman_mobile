import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = AppConfig.apiBaseUrl;
        final token = await _tokenStorage.read();
        if (token != null &&
            token.isNotEmpty &&
            !token.startsWith('admin_token_') &&
            !token.startsWith('local_')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  static String errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final response = error.response;
      if (response == null) {
        return 'Server backend tidak dapat dijangkau. Pastikan backend FastAPI aktif di ${AppConfig.apiBaseUrl}.';
      }
      final data = response.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List) {
          return detail.map((item) {
            if (item is Map) {
              final loc = item['loc'];
              final field = loc is List
                  ? loc.where((p) => p != 'body').join('.')
                  : '';
              final msg = item['msg']?.toString() ?? '';
              return field.isNotEmpty ? '$field: $msg' : msg;
            }
            return item.toString();
          }).join('; ');
        }
      }
      return '$fallback (HTTP ${response.statusCode}).';
    }
    return fallback;
  }
}
