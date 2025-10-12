import 'dart:ui';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:developer' as dev; // Still useful for actual debug console

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // --- REMOVED: No more on-screen debug logs ---
  // The List<String> _debugLogs = []; and _log() function definition are removed.
  // The calls to _log() within the _handleLogin() function will now refer
  // to a simple debugPrint, as originally intended for a production build.

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Reverted to simple debugPrint or removed logging calls for production
    dev.log('Login button pressed.', name: 'LoginScreen'); 
    FocusScope.of(context).unfocus();

    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty || password.isEmpty) {
      dev.log('Validation failed: Fields are empty.', name: 'LoginScreen');
      setState(() {
        _errorMessage = 'Please enter both Login ID and Password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dev.log('Calling AuthService.login...', name: 'LoginScreen');
      final Employee employee = await AuthService().login(loginId, password);
      
      if (!mounted) {
        dev.log('Login successful, but widget is no longer mounted.', name: 'LoginScreen');
        return;
      }

      dev.log('Login success! Navigating to /home.', name: 'LoginScreen');
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: employee,
      );
    } catch (e) {
      dev.log('Login failed with error: ${e.toString()}', name: 'LoginScreen');
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.white.withAlpha(51)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Sign In', textAlign: TextAlign.center, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('to continue to your account', textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(179))),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _loginIdController,
                            decoration: const InputDecoration(labelText: 'Login ID', prefixIcon: Icon(Icons.person_outline)),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: Colors.white), // Ensures text color is white
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            onSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(color: Colors.white), // Ensures text color is white
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent)),
                            ),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : ElevatedButton(onPressed: _handleLogin, child: const Text('Continue')),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

                // --- REMOVED: No more on-screen log viewer ---
                // The entire Container for _debugLogs is removed from the widget tree.
              ],
            ),
          ),
        ),
      ),
    );
  }
}