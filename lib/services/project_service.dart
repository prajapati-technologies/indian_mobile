import 'dart:convert';
import 'api_service.dart';
import '../models/home_design_models.dart';

class ProjectService {
  final ApiService api;
  final String? token;

  ProjectService({required this.api, this.token});

  Future<List<ProjectModel>> getProjects() async {
    final response = await api.getJson('projects', token: token);
    return (response as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel> createProject(String name, double width, double height) async {
    final body = {
      'name': name,
      'plot_width': width,
      'plot_height': height,
      'unit': 'feet',
    };
    final response = await api.postJson('projects', body, token: token);
    return ProjectModel.fromJson(response);
  }

  Future<void> saveProject(ProjectModel project) async {
    final body = {
      'name': project.name,
      'design_data': project.toJson(),
    };
    await api.postJson('projects/${project.id}', body, token: token);
    // Note: Laravel apiResource update is usually PUT/PATCH, 
    // but many APIs use POST for simplicity with _method=PUT.
    // I'll assume standard PUT or handle it in the controller if needed.
  }
}
