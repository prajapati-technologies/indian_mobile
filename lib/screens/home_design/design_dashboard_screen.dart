import 'package:flutter/material.dart';
import 'project_editor_screen.dart';
import 'create_project_screen.dart';
import '../../services/api_service.dart';
import '../../services/project_service.dart';
import '../../models/home_design_models.dart';

class DesignDashboardScreen extends StatefulWidget {
  final ApiService api;
  final String? token;
  final VoidCallback onRequireLogin;

  const DesignDashboardScreen({super.key, required this.api, required this.token, required this.onRequireLogin});

  @override
  State<DesignDashboardScreen> createState() => _DesignDashboardScreenState();
}

class _DesignDashboardScreenState extends State<DesignDashboardScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String? _error;
  ProjectService? _projectService;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _loadProjects();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(DesignDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token && widget.token != null) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    if (widget.token == null) return;
    setState(() => _isLoading = true);

    try {
      _projectService = ProjectService(api: widget.api, token: widget.token);
      final projects = await _projectService!.getProjects();
      if (mounted) setState(() { _projects = projects; _isLoading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Home Design', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreateNewButton(),
              const SizedBox(height: 32),
              const Text('My Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else if (_error != null)
                _buildErrorState()
              else if (_projects.isEmpty && widget.token != null)
                _buildEmptyState()
              else if (widget.token == null)
                _buildLoginPrompt()
              else
                ..._projects.map((p) => _buildProjectCard(p)),
              const SizedBox(height: 32),
              const Text('Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTemplateCategories(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNewButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (widget.token == null) { widget.onRequireLogin(); return; }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
          },
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.add_home_work_outlined, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Create New Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Start designing your dream space', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final sizeText = '${project.plotWidth.toStringAsFixed(0)}ft x ${project.plotHeight.toStringAsFixed(0)}ft';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.blue.shade50]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.architecture, color: Colors.blue.shade600, size: 28),
          ),
          title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(sizeText, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onPressed: () => _openProject(project),
          ),
          onTap: () => _openProject(project),
        ),
      ),
    );
  }

  void _openProject(ProjectModel project) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectEditorScreen(projectId: project.id)));
  }

  Widget _buildTemplateCategories() {
    final templates = [
      ('Modern 1BHK', Icons.apartment, Colors.teal, 30.0, 40.0),
      ('Luxury Villa', Icons.villa, Colors.amber.shade700, 60.0, 80.0),
      ('Minimal Studio', Icons.crib, Colors.blue, 20.0, 30.0),
      ('Indian Style', Icons.temple_hindu, Colors.deepOrange, 40.0, 50.0),
      ('Duplex House', Icons.home_work, Colors.indigo, 50.0, 60.0),
      ('Office Space', Icons.business, Colors.green.shade700, 30.0, 50.0),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: templates.map((t) => _templateCard(t.$1, t.$2, t.$3, t.$4, t.$5)).toList(),
      ),
    );
  }

  Widget _templateCard(String label, IconData icon, Color color, double w, double h) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (widget.token == null) { widget.onRequireLogin(); return; }
            // Navigate to create with pre-filled dimensions
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(height: 10),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${w}x${h} ft', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
          const SizedBox(height: 12),
          Text('Could not load projects', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProjects, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          const Text('No projects yet', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 4),
          Text('Create your first project above', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade400, size: 40),
          const SizedBox(height: 12),
          const Text('Login to save your projects', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onRequireLogin,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
