import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/teamly_provider.dart';
import '../../idea_generator/screens/idea_generator_screen.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../team/screens/team_screen.dart';
import 'dashboard_screen.dart';

bool ensureAuthenticated(BuildContext context, WidgetRef ref, String actionName) {
  final state = ref.read(teamlyProvider);
  if (state.isGuest) {
    final prompt = Uri.encodeComponent(
      'Perlu login terlebih dahulu untuk $actionName. Silakan masuk atau buat akun baru.',
    );
    context.push('/auth?mode=login&prompt=$prompt');
    return false;
  }
  return true;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _switchTab(int targetIndex) {
    setState(() => _index = targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigateTab: _switchTab),
      IdeaGeneratorScreen(onProjectCreated: () => _switchTab(0)),
      const TasksScreen(),
      const TeamScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline_rounded),
            selectedIcon: Icon(Icons.lightbulb_rounded),
            label: 'Ide',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_kanban_outlined),
            selectedIcon: Icon(Icons.view_kanban_rounded),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Tim',
          ),
        ],
      ),
    );
  }
}
