import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Brand(),
              const SizedBox(height: 42),
              const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sign in to continue to your workspace.', style: TextStyle(color: Color(0xFF85859A))),
              const SizedBox(height: 28),
              const Text('Email address'),
              const SizedBox(height: 8),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'name@email.com')),
              const SizedBox(height: 18),
              const Text('Password'),
              const SizedBox(height: 8),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Enter your password')),
              const SizedBox(height: 26),
              PrimaryButton(label: 'Sign in', onPressed: () => context.go('/app')),
              const SizedBox(height: 18),
              Center(child: TextButton(onPressed: () => context.go('/register'), child: const Text('Don’t have an account? Create one'))),
              const SizedBox(height: 10),
              const Center(child: Text('Connect this form to FastAPI authentication.', style: TextStyle(fontSize: 11, color: Color(0xFF9999A8)))),
            ]),
          ),
        ),
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF6558D3), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.grid_view_rounded, color: Colors.white)),
    const SizedBox(width: 10),
    const Text('teamly', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  ]);
}
