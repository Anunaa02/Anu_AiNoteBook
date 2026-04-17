import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack("Please enter email and password");
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.login(email, pass);
      if (data['token'] != null) {
        await ApiService.saveToken(data['token']);
        await ApiService.saveUser(
            data['user']?['name'] ?? email.split('@')[0], email);
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        _snack(data['message'] ?? "Login failed");
      }
    } catch (e) {
      _snack("Connection error. Make sure server is running.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF7c3aed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // Purple blob top-left
              Positioned(
                top: -60, left: -60,
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7c3aed).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                top: -30, right: -80,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFa855f7).withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.nightlight_round,
                          color: Color(0xFF7c3aed), size: 28),
                    ),
                    SizedBox(height: size.height * 0.04),
                    const Text("🐕", style: TextStyle(fontSize: 70)),
                    const SizedBox(height: 20),
                    // Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7c3aed).withValues(alpha: 0.12),
                            blurRadius: 30, offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text("Welcome Back!",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1a0033))),
                          ),
                          const SizedBox(height: 24),
                          const Text("Email",
                              style: TextStyle(
                                  color: Color(0xFF4c1d95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _lightField(
                            controller: _emailCtrl,
                            hint: "anu@email.com",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          const Text("Password",
                              style: TextStyle(
                                  color: Color(0xFF4c1d95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _lightField(
                            controller: _passCtrl,
                            hint: "••••••••••",
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade400,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("Forgot Password >",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF7c3aed)))
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7c3aed),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      elevation: 4,
                                      shadowColor: const Color(0xFF7c3aed)
                                          .withValues(alpha: 0.4),
                                    ),
                                    child: const Text("Login",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen())),
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: "Sign Up >",
                                      style: TextStyle(
                                          color: Color(0xFF7c3aed),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1a0033), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F0FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7c3aed), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}