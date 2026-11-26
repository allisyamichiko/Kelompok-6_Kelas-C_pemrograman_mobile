import '../../../core/network/api_client.dart';
import '../../../shared/models/teamly_models.dart';

class TeamRepository {
  TeamRepository(this._client);
  final ApiClient _client;

  Future<List<MemberModel>> getMembers(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/members');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MemberModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<MemberModel> addMember(int projectId, Map<String, dynamic> payload) async {
    final response =
        await _client.dio.post('/api/projects/$projectId/members', data: payload);
    return MemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeMember(int projectId, int memberId) async {
    await _client.dio.delete('/api/projects/$projectId/members/$memberId');
  }
}
