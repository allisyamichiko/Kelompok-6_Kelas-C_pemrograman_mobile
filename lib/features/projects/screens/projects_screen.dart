import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))]),
    body: ListView(padding: const EdgeInsets.all(20), children: const [
      Text('Your team workspaces', style: TextStyle(color: AppTheme.muted)),
      SizedBox(height: 18),
      _ProjectCard(name: 'Website Redesign', detail: '6 members · 12 tasks', progress: .72, color: Color(0xFF6558D3)),
      _ProjectCard(name: 'Mobile App', detail: '4 members · 8 tasks', progress: .45, color: Color(0xFF299D8F)),
      _ProjectCard(name: 'Campus Event', detail: '8 members · 15 tasks', progress: .28, color: Color(0xFFE39A43)),
    ]),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.name, required this.detail, required this.progress, required this.color});
  final String name, detail; final double progress; final Color color;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 10, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 12), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const Icon(Icons.more_horiz)]),
    const SizedBox(height: 8), Text(detail, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
    const SizedBox(height: 18), LinearProgressIndicator(value: progress, minHeight: 7, borderRadius: BorderRadius.circular(10), color: color, backgroundColor: const Color(0xFFEDECF3)),
    const SizedBox(height: 8), Text('${(progress * 100).round()}% completed', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
  ]));
}
