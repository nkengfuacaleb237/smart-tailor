import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  String _role = 'customer';
  bool _isPublic = true;
  bool _isLoading = false;
  String _error = '';
  int _step = 1; // 1 = role, 2 = details, 3 = preferences

  final List<String> _allCategories = [
    'Ankara', 'Kaftan', 'Formal', 'Casual', 'Wedding',
    'Traditional', 'Corporate', 'Evening', 'Kids', 'Sportswear'
  ];
  final Set<String> _selectedCategories = {};

  late AnimationController _formController;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    _formController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _locationCtrl.dispose();
    _contactCtrl.dispose(); _experienceCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    _formController.reset();
    setState(() => _step++);
    _formController.forward();
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name and email are required');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': _passwordCtrl.text,
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim().toLowerCase(),
          'phone': _phoneCtrl.text.trim(),
          'role': _role,
          'dress_preferences': _selectedCategories.join(','),
          'skills': _selectedCategories.join(','),
          'location': _locationCtrl.text.trim(),
          'contact_info': _contactCtrl.text.trim(),
          'years_experience': int.tryParse(_experienceCtrl.text) ?? 0,
          'is_public': _isPublic,
        }),
      );
      final user = jsonDecode(res.body);
      if (mounted) {
        Provider.of<AppState>(context, listen: false).setUser(user);
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false);
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2E0A), Color(0xFF1B5E20), Color(0xFF0D3B0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_step > 1) {
                          _formController.reset();
                          setState(() => _step--);
                          _formController.forward();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    // Step indicators
                    Row(children: List.generate(3, (i) => Container(
                      width: i + 1 == _step ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i + 1 <= _step
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4)),
                    ))),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _step == 1 ? 'Join Smart Tailor ✂️'
                        : _step == 2 ? 'Your Details 📝'
                        : 'Your Style 👗',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text(
                      _step == 1 ? 'Who are you joining as?'
                        : _step == 2 ? 'Tell us about yourself'
                        : _role == 'tailor'
                          ? 'What styles can you sew?'
                          : 'What styles do you love?',
                      style: const TextStyle(color: Colors.white60, fontSize: 15)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 40, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _formFade,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // STEP 1 — Role selection
                          if (_step == 1) ...[
                            _roleCard(
                              role: 'customer',
                              icon: Icons.shopping_bag_outlined,
                              title: 'I\'m a Customer',
                              subtitle: 'Browse styles, place orders, try on dresses',
                            ),
                            const SizedBox(height: 12),
                            _roleCard(
                              role: 'tailor',
                              icon: Icons.content_cut,
                              title: 'I\'m a Tailor',
                              subtitle: 'Upload styles, manage orders, grow your business',
                            ),
                            const SizedBox(height: 32),
                            _nextButton('Continue', _nextStep),
                          ],

                          // STEP 2 — Details
                          if (_step == 2) ...[
                            _inputField(_nameCtrl, 'Full Name',
                              Icons.person_outline),
                            const SizedBox(height: 14),
                            _inputField(_emailCtrl, 'Email Address',
                              Icons.email_outlined,
                              type: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            StatefulBuilder(
                              builder: (ctx, setLocal) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(14)),
                                child: TextField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Create Password',
                                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
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
                                        color: const Color(0xFF8E8E93), size: 20)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _inputField(_phoneCtrl, 'Phone Number',
                              Icons.phone_outlined,
                              type: TextInputType.phone),
                            if (_role == 'tailor') ...[
                              const SizedBox(height: 14),
                              _inputField(_locationCtrl, 'City / Location',
                                Icons.location_on_outlined),
                              const SizedBox(height: 14),
                              _inputField(_contactCtrl, 'WhatsApp / Contact',
                                Icons.chat_outlined),
                              const SizedBox(height: 14),
                              _inputField(_experienceCtrl, 'Years of Experience',
                                Icons.workspace_premium_outlined,
                                type: TextInputType.number),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(14)),
                                child: Row(children: [
                                  const Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Make profile public',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                      Text('Customers can find and order from you',
                                        style: TextStyle(
                                          color: Color(0xFF8E8E93), fontSize: 12)),
                                    ],
                                  )),
                                  Switch(
                                    value: _isPublic,
                                    onChanged: (v) => setState(() => _isPublic = v),
                                    activeColor: const Color(0xFF1B5E20)),
                                ]),
                              ),
                            ],
                            if (_error.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
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
                            const SizedBox(height: 24),
                            _nextButton('Continue', _nextStep),
                          ],

                          // STEP 3 — Preferences
                          if (_step == 3) ...[
                            Wrap(
                              spacing: 10, runSpacing: 10,
                              children: _allCategories.map((cat) {
                                final selected = _selectedCategories.contains(cat);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (selected) _selectedCategories.remove(cat);
                                    else _selectedCategories.add(cat);
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFFF2F2F7),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: selected ? [
                                        BoxShadow(
                                          color: const Color(0xFF1B5E20).withOpacity(0.3),
                                          blurRadius: 8, offset: const Offset(0, 4))
                                      ] : [],
                                    ),
                                    child: Text(cat,
                                      style: TextStyle(
                                        color: selected
                                          ? Colors.white
                                          : const Color(0xFF3A3A3C),
                                        fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                        fontSize: 14)),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                            if (_error.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10)),
                                child: Text(_error,
                                  style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                  elevation: 0),
                                child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                  : const Text('Create Account 🎉',
                                      style: TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
            width: 2),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B5E20) : Colors.white,
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
              size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16,
                color: selected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF1C1C1E))),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(
                color: Color(0xFF8E8E93), fontSize: 12)),
            ],
          )),
          if (selected)
            const Icon(Icons.check_circle,
              color: Color(0xFF1B5E20), size: 22),
        ]),
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

  Widget _nextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
          elevation: 0),
        child: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
