import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({Key? key}) : super(key: key);

  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isSignInMode = true; // Track whether it's sign-in mode or sign-up mode
  String _errorMessage = ''; // Store error messages

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignInMode ? 'Sign In' : 'Sign Up'), // Update title based on mode
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSignInMode ? _signInWithEmailAndPassword : _signUpWithEmailAndPassword,
              child: Text(_isSignInMode ? 'Sign In' : 'Sign Up'), // Update button text based on mode
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignInMode = !_isSignInMode; // Toggle between sign-in and sign-up modes
                  _errorMessage = ''; // Clear previous error message when switching modes
                });
              },
              child: Text(_isSignInMode ? 'Switch to Sign Up' : 'Switch to Sign In'), // Update switch button text based on mode
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle sign in errors
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    }
  }

  Future<void> _signUpWithEmailAndPassword() async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle sign up errors
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      default:
        return 'An error occurred. Please try again later.';
    }
  }
}
