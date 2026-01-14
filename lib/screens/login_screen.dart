import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.8),
            radius: 1.5,
            colors: [Color(0xFF1E293B), Color(0xFF000000)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.robot,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 20),
              Text(
                'HUMOSAFE',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 400.ms),
              Text(
                _isLogin ? 'User Login' : 'Register New User',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF94A3B8),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 40),
              if (!_isLogin)
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  icon: FontAwesomeIcons.user,
                ).animate().slideX(begin: -0.1).fadeIn(),
              if (!_isLogin) const SizedBox(height: 15),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email Address',
                icon: FontAwesomeIcons.envelope,
              ).animate().slideX(begin: -0.1, delay: 600.ms).fadeIn(),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: FontAwesomeIcons.lock,
                isPassword: true,
              ).animate().slideX(begin: 0.1, delay: 700.ms).fadeIn(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          try {
                            if (_isLogin) {
                              await authProvider.login(
                                _emailController.text,
                                _passwordController.text,
                              );
                            } else {
                              await authProvider.register(
                                _emailController.text,
                                _passwordController.text,
                                _nameController.text,
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Action Failed: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'SECURE LOGIN' : 'CREATE ACCOUNT',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            FaIcon(
                              _isLogin
                                  ? FontAwesomeIcons.shieldHalved
                                  : FontAwesomeIcons.userPlus,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ).animate().slideY(begin: 0.2, delay: 800.ms).fadeIn(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF06B6D4),
                    fontSize: 14,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),
              const SizedBox(height: 25),
              Text(
                'v1.0.0 | Connected to Firebase',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14.0),
            child: FaIcon(icon, size: 18, color: const Color(0xFF94A3B8)),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
