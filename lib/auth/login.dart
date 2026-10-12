import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup.dart';
import '../main/HomeScreen.dart'; // Adjust the import based on your project structure
import '../helpers/databaseHelper.dart'; // Import DatabaseHelper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
    } else {
      await prefs.remove('email');
    }
  }

  void _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      final email =
          _emailController.text.trim(); // Trim to avoid whitespace issues
      final password = _passwordController.text;

      try {
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user != null && user['password'] == password) {
          await _saveCredentials();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedInEmail', email);
          print('Saved loggedInEmail: $email'); // Debug log

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful')),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during login: $e')),
        );
      }
    }
  }

  void _onCreateAccountPressed() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/img/logo.png',
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                  semanticLabel: 'OCR App Logo',
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'OCR App Login Title',
                ),
                Text(
                  'Please enter your login credentials!',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'OCR App Login Title',
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Color(0xFF6994C6)),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.onSurface),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6994C6)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF6994C6), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: colorScheme.error, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: colorScheme.error, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.onSurface),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6994C6)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF6994C6), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: colorScheme.error, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: colorScheme.error, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _onCreateAccountPressed,
                  icon: Icon(
                    Icons.person_add,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Create an Account',
                    style: TextStyle(
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.primary,
                      fontSize: 16,
                    ),
                    semanticsLabel: 'Create an Account Link',
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    child: CheckboxListTile(
                      title: const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontFamily: 'GlacialIndifference',
                          fontSize: 14,
                        ),
                      ),
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6994C6),
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF6994C6)),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    semanticsLabel: 'Login Button',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
