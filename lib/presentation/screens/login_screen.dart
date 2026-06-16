import 'package:flutter/material.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/layout.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
                      child: const Icon(FontAwesomeIcons.leaf, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'AgriSmart',
                      style: TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'Your Intelligent Farming Partner',
                      style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 48),
                    
                    // Glassmorphism Login Card
                    Container(
                      width: 450,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select your portal to continue',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 40),
                          
                          _buildModernRoleCard(
                            context,
                            'Farmer Portal',
                            'Analyze crops, soil & diseases',
                            'Farmer',
                            FontAwesomeIcons.tractor,
                            Colors.orange.shade400,
                          ),
                          const SizedBox(height: 20),
                          _buildModernRoleCard(
                            context,
                            'Admin / Expert',
                            'System health & user metrics',
                            'Admin',
                            FontAwesomeIcons.userShield,
                            Colors.blue.shade400,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'AgriSmart v2.0.4',
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
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

  Widget _buildModernRoleCard(BuildContext context, String title, String subtitle, String role, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainLayout(userRole: role)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }
}
