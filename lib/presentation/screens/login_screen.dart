import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/api_config.dart';
import 'package:agrismart/presentation/widgets/layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final username = _userCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Hardcoded check for Admin Portal
    if (email == 'admin@gmail.com' && password == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout(userRole: 'Admin')),
      );
      return;
    }

    // 2. Database check for other users (Farmers)
    try {
      final endpoint = _isLogin ? 'login' : 'register';
      final payload = _isLogin 
        ? {'email': email, 'password': password}
        : {'username': username, 'email': email, 'password': password};

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'] ?? 'Farmer';
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainLayout(userRole: role)),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['detail'] ?? 'Invalid Email or Password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed. Make sure backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF004D40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background patterns
            Positioned(
              top: -100, right: -100,
              child: Icon(FontAwesomeIcons.leaf, size: 300, color: Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -50, left: -50,
              child: Icon(FontAwesomeIcons.seedling, size: 200, color: Colors.white.withOpacity(0.05)),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Area
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(FontAwesomeIcons.leaf, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AgriSmart',
                      style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'Your Intelligent Farming Partner',
                      style: TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 32),
                    
                    // Glassmorphism Login Card
                    Container(
                      width: 420,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              _isLogin ? 'Sign In' : 'Create Account',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                border: Border.all(color: Colors.red.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Username field (only in Register mode)
                          if (!_isLogin) ...[
                            _buildInputField(
                              controller: _userCtrl,
                              hint: 'Enter your Name',
                              label: 'Full Name',
                              icon: Icons.person_outlined,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          _buildInputField(
                            controller: _emailCtrl,
                            hint: 'Enter your Email',
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          _buildInputField(
                            controller: _passCtrl,
                            hint: 'Enter your Password',
                            label: 'Password',
                            icon: Icons.lock_outlined,
                            obscureText: _obscureText,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscureText = !_obscureText);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login/Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE65100),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Toggle form link
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: Icon(icon, color: Colors.white70, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
