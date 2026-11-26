import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Create your account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Set up your Teamly workspace.', style: TextStyle(color: Color(0xFF85859A))),
        const SizedBox(height: 28),
        const Text('Full name'), const SizedBox(height: 8),
        TextField(controller: name, decoration: const InputDecoration(hintText: 'Your name')),
        const SizedBox(height: 18),
        const Text('Email address'), const SizedBox(height: 8),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'name@email.com')),
        const SizedBox(height: 18),
        const Text('Password'), const SizedBox(height: 8),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Create a password')),
        const SizedBox(height: 26),
        PrimaryButton(label: 'Create account', onPressed: () => context.go('/app')),
        const SizedBox(height: 12),
        const Text('Registration API integration is a TODO for the migration.', style: TextStyle(fontSize: 11, color: Color(0xFF9999A8))),
      ]),
    )),
  );
}
