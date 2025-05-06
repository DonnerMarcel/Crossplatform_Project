// lib/screens/login_screen.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/screens/register_screen.dart';
import '../providers.dart';
import 'group_list_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credentials.user?.uid;
      if (uid != null) {
        ref.read(userIdProvider.notifier).state = uid;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GroupListScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/money.png', height: 100),
                    const SizedBox(height: 64),
                    Text('Login', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildInputDecoration(
                        context: context,
                        labelText: 'Email',
                        hintText: 'your@mail.com',
                        prefixIconData: Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your email.' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _buildInputDecoration(
                        context: context,
                        labelText: 'Password',
                        hintText: 'A safe password',
                        prefixIconData: Icons.lock_outline,
                      ),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your password.' : null,
                    ),
                    if (_error != null)
                      Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                              textAlign: TextAlign.left,
                            ),
                          ]
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Not registered yet? Create an account!"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      )
    );
  }
}

InputDecoration _buildInputDecoration({
  required String labelText,
  String? hintText,
  IconData? prefixIconData,
  String? suffixText,
  BuildContext? context,
}) {
  final iconColor = context != null
      ? Theme.of(context).colorScheme.primary
      : null;

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: Colors.black.withOpacity(0.04),
    prefixIcon: prefixIconData != null
        ? Icon(prefixIconData, color: iconColor)
        : null,
    suffixText: suffixText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}
