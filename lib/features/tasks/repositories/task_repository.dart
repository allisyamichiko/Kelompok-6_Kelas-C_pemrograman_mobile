import '../../../core/network/api_client.dart';
import '../../../shared/models/teamly_models.dart';

class TaskRepository {
  TaskRepository(this._client);
  final ApiClient _client;

  Future<List<TaskModel>> getTasks(int projectId) async {
    final response = await _client.dio.get('/api/projects/$projectId/tasks');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<TaskModel> createTask(int projectId, Map<String, dynamic> payload) async {
    final response =
        await _client.dio.post('/api/projects/$projectId/tasks', data: payload);
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> payload) async {
    final response = await _client.dio.patch('/api/tasks/$taskId', data: payload);
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.dio.delete('/api/tasks/$taskId');
  }

  Future<List<TaskComment>> getComments(String taskId) async {
    final response = await _client.dio.get('/api/tasks/$taskId/comments');
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((j) {
        return TaskComment(
          id: (j['id'] ?? '').toString(),
          author: (j['author_name'] ?? 'Anggota').toString(),
          role: (j['author_role'] ?? 'Anggota Tim').toString(),
          text: (j['text'] ?? '').toString(),
          time: (j['created_at'] ?? '').toString().split('T').first,
        );
      }).toList();
    }
    return [];
  }

  Future<TaskComment> addComment(String taskId, String text) async {
    final response = await _client.dio.post('/api/tasks/$taskId/comments', data: {'text': text});
    final j = response.data as Map<String, dynamic>;
    return TaskComment(
      id: (j['id'] ?? '').toString(),
      author: (j['author_name'] ?? 'Anggota').toString(),
      role: (j['author_role'] ?? 'Anggota Tim').toString(),
      text: (j['text'] ?? '').toString(),
      time: 'Baru saja',
    );
  }
}
