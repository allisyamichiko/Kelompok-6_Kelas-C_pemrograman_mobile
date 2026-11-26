import '../../../core/network/api_client.dart';
import '../../../shared/models/teamly_models.dart';

class ProjectRepository {
  ProjectRepository(this._client);
  final ApiClient _client;

  Future<List<ProjectModel>> getProjects() async {
    final response = await _client.dio.get('/api/projects');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProjectModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<ProjectModel> createProject(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/projects', data: payload);
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProject(int projectId) async {
    await _client.dio.delete('/api/projects/$projectId');
  }

  Future<Map<String, dynamic>> getAnalytics(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/analytics');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReport(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/report');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getNotifications(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/notifications');
    return response.data is List ? response.data as List : [];
  }
}
