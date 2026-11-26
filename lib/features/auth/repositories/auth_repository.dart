import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/teamly_models.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final UserModel user;
}

class RegisterResult {
  const RegisterResult({
    required this.message,
    required this.requiresVerification,
    this.auth,
  });
  final String message;
  final bool requiresVerification;
  final AuthResult? auth;
}

class AuthRepository {
  AuthRepository(this._client, this._storage);
  final ApiClient _client;
  final TokenStorage _storage;

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _client.dio.post('/api/auth/login', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = (data['access_token'] ?? '').toString();
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    if (token.isEmpty) throw Exception('Access token tidak ditemukan.');
    await _storage.save(token);
    await _storage.saveUser(user.toJson());
    return AuthResult(token: token, user: user);
  }

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post('/api/auth/register', data: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final msg = (data['message'] ?? 'Akun berhasil dibuat.').toString();
    final requiresVerification = data['requires_verification'] as bool? ?? false;
    final token = data['access_token']?.toString();
    final userMap = data['user'];

    if (!requiresVerification && token != null && token.isNotEmpty && userMap is Map<String, dynamic>) {
      final user = UserModel.fromJson(userMap);
      await _storage.save(token);
      await _storage.saveUser(user.toJson());
      return RegisterResult(
        message: msg,
        requiresVerification: false,
        auth: AuthResult(token: token, user: user),
      );
    }

    return RegisterResult(message: msg, requiresVerification: true);
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _client.dio.post('/api/auth/verify-email', data: {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
    final data = response.data as Map<String, dynamic>;
    final token = (data['access_token'] ?? '').toString();
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.save(token);
    await _storage.saveUser(user.toJson());
    return AuthResult(token: token, user: user);
  }

  Future<String> resendVerification({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post('/api/auth/verification/resend', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return (data['message'] ?? 'Kode verifikasi baru telah dikirim.').toString();
  }

  Future<UserModel> me() async {
    final response = await _client.dio.get('/api/auth/me');
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _storage.saveUser(user.toJson());
    return user;
  }

  Future<void> saveLocalSession(String token, UserModel user) async {
    await _storage.save(token);
    await _storage.saveUser(user.toJson());
  }

  Future<String?> readToken() => _storage.read();
  Future<Map<String, dynamic>?> readCachedUser() => _storage.readUser();
  Future<void> logout() => _storage.clear();
}
