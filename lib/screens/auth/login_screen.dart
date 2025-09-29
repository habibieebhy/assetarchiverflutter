import 'dart:ui';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// STEP 1: Convert to a StatefulWidget to manage state.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // STEP 2: Create TextEditingControllers to get input from the text fields.
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  // STEP 3: Add state variables for loading and error messages.
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // STEP 4: Create the function to handle the login logic.
  Future<void> _handleLogin() async {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    if (_loginIdController.text.isEmpty || _passwordController.text.isEmpty) {
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
      // Call the AuthService to perform the login.
      // FIXED: Added the explicit type `Employee` to make the import necessary.
      final Employee employee = await AuthService().login(
        _loginIdController.text,
        _passwordController.text,
      );

      // On success, navigate to the home screen and pass the employee data.
      // pushNamedAndRemoveUntil clears the navigation stack so the user can't go back.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false, // This predicate removes all previous routes.
          arguments: employee, // Pass the logged-in employee object.
        );
      }
    } catch (e) {
      // On failure, update the state to show the error message.
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      // Ensure the loading indicator is turned off, even if an error occurs.
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
            child: ClipRRect(
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
                      Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'to continue to your account',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Assign the controller to the TextField.
                      TextField(
                        controller: _loginIdController,
                        decoration: const InputDecoration(
                          labelText: 'Login ID',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      // Assign the controller to the TextField.
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 24),
                      // Show an error message if it exists.
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.amberAccent),
                          ),
                        ),
                      // Show a progress indicator or the button.
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              // Call your login handler.
                              onPressed: _handleLogin,
                              child: const Text('Continue'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
        ),
      ),
    );
  }
}

