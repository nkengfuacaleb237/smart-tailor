import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  String _role = 'customer';
  bool _isPublic = true;
  bool _isLoading = false;
  String _error = '';

  final List<String> _allCategories = [
    'Ankara', 'Kaftan', 'Formal', 'Casual', 'Wedding',
    'Traditional', 'Corporate', 'Evening', 'Kids', 'Sportswear'
  ];
  final Set<String> _selectedCategories = {};

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
      setState(() => _error = 'Connection error. Is Flask running?');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _role = 'customer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _role == 'customer'
                          ? const Color(0xFF1B5E20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Customer', textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _role == 'customer' ? Colors.white : const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w600)),
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _role = 'tailor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _role == 'tailor'
                          ? const Color(0xFF1B5E20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Tailor', textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _role == 'tailor' ? Colors.white : const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w600)),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1B5E20)))),
                  const SizedBox(height: 14),
                  TextField(controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1B5E20)))),
                  const SizedBox(height: 14),
                  TextField(controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF1B5E20)))),
                  if (_role == 'tailor') ...[
                    const SizedBox(height: 14),
                    TextField(controller: _locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location (City)',
                        prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF1B5E20)))),
                    const SizedBox(height: 14),
                    TextField(controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'WhatsApp / Contact Info',
                        prefixIcon: Icon(Icons.chat_outlined, color: Color(0xFF1B5E20)))),
                    const SizedBox(height: 14),
                    TextField(controller: _experienceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Years of Experience',
                        prefixIcon: Icon(Icons.workspace_premium_outlined, color: Color(0xFF1B5E20)))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Make profile public',
                          style: TextStyle(fontSize: 15, color: Color(0xFF1C1C1E))),
                        Switch(
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                          activeColor: const Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _role == 'tailor'
                ? 'Select dress types you can sew:'
                : 'Select styles you love:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E)),
            ),
            const SizedBox(height: 4),
            Text(
              _role == 'tailor'
                ? 'Customers will find you through these'
                : 'Your feed will show these styles',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _allCategories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _selectedCategories.remove(cat);
                    else _selectedCategories.add(cat);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1B5E20) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF1B5E20) : const Color(0xFFE5E5EA)),
                    ),
                    child: Text(cat,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF3A3A3C),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14)),
                  ),
                );
              }).toList(),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('CREATE ACCOUNT'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
