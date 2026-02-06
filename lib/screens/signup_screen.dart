import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    final userType = args ?? 'patient';

    // This is a placeholder. Implement the signup form that writes nodes under users/{userType}/{mobile}
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up: $userType')),
      body: const Center(
        child: Text('Implement signup UI here. Use userType to decide fields.'),
      ),
    );
  }
}
