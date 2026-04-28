import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'signup_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _error = '';

  late AnimationController _bgController;
  late AnimationController _formController;
  late AnimationController _iconController;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _iconFloat;

  final List<_FloatingIcon> _icons = [
    _FloatingIcon(Icons.content_cut, 0.1, 0.15, 28),
    _FloatingIcon(Icons.checkroom_outlined, 0.8, 0.1, 32),
    _FloatingIcon(Icons.straighten_outlined, 0.15, 0.45, 24),
    _FloatingIcon(Icons.palette_outlined, 0.75, 0.4, 26),
    _FloatingIcon(Icons.auto_awesome, 0.5, 0.08, 20),
    _FloatingIcon(Icons.design_services_outlined, 0.85, 0.7, 28),
    _FloatingIcon(Icons.star_outline, 0.05, 0.72, 22),
    _FloatingIcon(Icons.diamond_outlined, 0.6, 0.82, 24),
    _FloatingIcon(Icons.workspace_premium_outlined, 0.3, 0.88, 20),
    _FloatingIcon(Icons.brush_outlined, 0.9, 0.25, 22),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _formController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _iconController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _formSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    _iconFloat = Tween<double>(begin: 0, end: 1).animate(_iconController);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _formController.dispose();
    _iconController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim().toLowerCase(),
          'password': _passwordCtrl.text,
        }),
      );
      if (res.statusCode == 404) {
        setState(() => _error = 'No account found. Please sign up first.');
      } else if (res.statusCode == 401) {
        setState(() => _error = 'Incorrect password. Please try again.');
      } else {
        final user = jsonDecode(res.body);
        if (mounted) {
          Provider.of<AppState>(context, listen: false).setUser(user);
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainShell()));
        }
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Check your internet.');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF0A2E0A),
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF0D3B0D),
              ],
              stops: [
                0.0,
                _bgController.value * 0.4 + 0.2,
                _bgController.value * 0.3 + 0.5,
                1.0,
              ],
            ),
          ),
          child: child,
        ),
        child: Stack(
          children: [
            // Floating icons
            ..._icons.map((fi) => AnimatedBuilder(
              animation: _iconFloat,
              builder: (context, _) {
                final offset = sin(_iconFloat.value * pi * 2 + fi.phase) * 8;
                return Positioned(
                  left: fi.x * size.width,
                  top: fi.y * size.height + offset,
                  child: Icon(fi.icon, size: fi.size,
                    color: Colors.white.withOpacity(0.12)));
              },
            )),

            SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: size.height,
                  child: Column(
                    children: [
                      const Spacer(),

                      // Logo
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 24, offset: const Offset(0, 8))],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white,
                              child: const Center(
                                child: Text('ST', style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 32, fontWeight: FontWeight.w900)))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Smart Tailor',
                        style: TextStyle(color: Colors.white,
                          fontSize: 32, fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                      const SizedBox(height: 6),
                      const Text('Your Style. Perfected.',
                        style: TextStyle(color: Colors.white60, fontSize: 15)),

                      const Spacer(),

                      // Form card
                      AnimatedBuilder(
                        animation: _formController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _formSlide.value),
                          child: Opacity(opacity: _formFade.value, child: child),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 40, offset: const Offset(0, 20))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome Back 👋',
                                style: TextStyle(fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C1C1E))),
                              const SizedBox(height: 4),
                              const Text('Sign in to continue',
                                style: TextStyle(color: Color(0xFF8E8E93),
                                  fontSize: 14)),
                              const SizedBox(height: 24),

                              // Email
                              _inputField(_emailCtrl, 'Email address',
                                Icons.email_outlined,
                                type: TextInputType.emailAddress),
                              const SizedBox(height: 14),

                              // Password
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(14)),
                                child: TextField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFAAAAAA)),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B5E20),
                                        borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.lock_outline,
                                        color: Colors.white, size: 18)),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                      child: Icon(
                                        _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                        color: const Color(0xFF8E8E93),
                                        size: 20)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16)),
                                ),
                              ),

                              if (_error.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline,
                                      color: Colors.red, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error,
                                      style: const TextStyle(
                                        color: Colors.red, fontSize: 12))),
                                  ]),
                                ),
                              ],
                              const SizedBox(height: 20),

                              // Sign in button
                              SizedBox(
                                width: double.infinity, height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                    elevation: 0),
                                  child: _isLoading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In',
                                        style: TextStyle(fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(children: [
                                Expanded(child: Divider(
                                  color: Colors.grey.shade200)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('or', style: TextStyle(
                                    color: Color(0xFFAAAAAA), fontSize: 13))),
                                Expanded(child: Divider(
                                  color: Colors.grey.shade200)),
                              ]),
                              const SizedBox(height: 20),

                              // Create account button
                              SizedBox(
                                width: double.infinity, height: 54,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                      const SignupScreen())),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF1B5E20), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                                  child: const Text('Create Account',
                                    style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B5E20))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('"Your Style. Perfected."',
                        style: TextStyle(color: Colors.white38,
                          fontSize: 12, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 18)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final double x, y, size, phase;
  _FloatingIcon(this.icon, this.x, this.y, this.size)
    : phase = Random().nextDouble() * pi * 2;
}
