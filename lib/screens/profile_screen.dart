import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../app_state.dart';
import 'login_screen.dart';

const _base = 'https://smart-tailor-backend-mi4z.onrender.com';
const _cloudName = 'ds9mzohwn';
const _uploadPreset = 'smart-tailor';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  File? _newAvatar;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _skillsCtrl;
  late TextEditingController _prefsCtrl;
  late TextEditingController _expCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameCtrl = TextEditingController(text: user?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    _locationCtrl = TextEditingController(text: user?['location'] ?? '');
    _contactCtrl = TextEditingController(text: user?['contact_info'] ?? '');
    _skillsCtrl = TextEditingController(text: user?['skills'] ?? '');
    _prefsCtrl = TextEditingController(text: user?['dress_preferences'] ?? '');
    _expCtrl = TextEditingController(
      text: (user?['years_experience'] ?? 0).toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _locationCtrl.dispose();
    _contactCtrl.dispose(); _skillsCtrl.dispose(); _prefsCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          const Text('Profile Photo', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.camera_alt_outlined, color: Color(0xFF1B5E20))),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.photo_library_outlined, color: Color(0xFF1B5E20))),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<String?> _uploadAvatar() async {
    if (_newAvatar == null) return null;
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'));
      req.fields['upload_preset'] = _uploadPreset;
      req.files.add(await http.MultipartFile.fromPath('file', _newAvatar!.path));
      final res = await req.send();
      final body = jsonDecode(await res.stream.bytesToString());
      return body['secure_url'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userId = appState.userId;

      String? avatarUrl;
      if (_newAvatar != null) avatarUrl = await _uploadAvatar();

      final body = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact_info': _contactCtrl.text.trim(),
        'skills': _skillsCtrl.text.trim(),
        'dress_preferences': _prefsCtrl.text.trim(),
        'years_experience': int.tryParse(_expCtrl.text) ?? 0,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      final res = await http.put(
        Uri.parse('$_base/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final updated = jsonDecode(res.body);
      appState.setUser(Map<String, dynamic>.from(updated));

      setState(() { _editing = false; _saving = false; _newAvatar = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'),
          backgroundColor: Color(0xFF1B5E20)));
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever')),
        ],
      ),
    );
    if (confirm != true) return;

    final userId = Provider.of<AppState>(context, listen: false).userId;
    await http.delete(Uri.parse('$_base/api/users/$userId'));
    if (mounted) {
      Provider.of<AppState>(context, listen: false).clearUser();
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isTailor = appState.isTailor;
    final avatarUrl = user?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                  GestureDetector(
                    onTap: () {
                      if (_editing) {
                        _saveProfile();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _editing
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20)),
                      child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Text(_editing ? 'Save' : 'Edit',
                            style: TextStyle(
                              color: _editing
                                ? Colors.white
                                : const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar
              GestureDetector(
                onTap: _editing ? _pickAvatar : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFF1B5E20),
                      backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!) as ImageProvider
                        : avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl) as ImageProvider
                          : null,
                      child: _newAvatar == null && avatarUrl.isEmpty
                        ? Text((user?['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                              fontSize: 36, fontWeight: FontWeight.bold))
                        : null,
                    ),
                    if (_editing)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (!_editing) ...[
                Text(user?['name'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    (user?['role'] ?? 'customer').toUpperCase(),
                    style: const TextStyle(color: Color(0xFF1B5E20),
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text(user?['email'] ?? '',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
              ],
              const SizedBox(height: 24),

              // Edit form or info display
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editing) ...[
                      // Edit fields
                      _editField('Full Name', _nameCtrl,
                        Icons.person_outline),
                      const SizedBox(height: 12),
                      _editField('Phone', _phoneCtrl,
                        Icons.phone_outlined,
                        type: TextInputType.phone),
                      const SizedBox(height: 12),
                      _editField('Location', _locationCtrl,
                        Icons.location_on_outlined),
                      if (isTailor) ...[
                        const SizedBox(height: 12),
                        _editField('Contact Info (WhatsApp/Social)',
                          _contactCtrl, Icons.chat_outlined),
                        const SizedBox(height: 12),
                        _editField('Skills (e.g. Ankara, Suits)',
                          _skillsCtrl, Icons.design_services_outlined),
                        const SizedBox(height: 12),
                        _editField('Years of Experience', _expCtrl,
                          Icons.workspace_premium_outlined,
                          type: TextInputType.number),
                      ] else ...[
                        const SizedBox(height: 12),
                        _editField('Dress Preferences (e.g. Ankara, Casual)',
                          _prefsCtrl, Icons.favorite_outline),
                      ],
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _editing = false),
                        child: const Center(
                          child: Text('Cancel',
                            style: TextStyle(color: Color(0xFF8E8E93),
                              fontSize: 14)),
                        ),
                      ),
                    ] else ...[
                      // View mode
                      _infoRow(Icons.phone_outlined, 'Phone',
                        user?['phone']?.isNotEmpty == true
                          ? user!['phone'] : 'Not set'),
                      const Divider(height: 1, indent: 40),
                      _infoRow(Icons.location_on_outlined, 'Location',
                        user?['location']?.isNotEmpty == true
                          ? user!['location'] : 'Not set'),
                      if (isTailor) ...[
                        const Divider(height: 1, indent: 40),
                        _infoRow(Icons.workspace_premium_outlined,
                          'Experience',
                          '${user?['years_experience'] ?? 0} years'),
                        const Divider(height: 1, indent: 40),
                        _infoRow(Icons.chat_outlined, 'Contact',
                          user?['contact_info']?.isNotEmpty == true
                            ? user!['contact_info'] : 'Not set'),
                        const Divider(height: 1, indent: 40),
                        _infoRow(Icons.design_services_outlined, 'Skills',
                          user?['skills']?.isNotEmpty == true
                            ? user!['skills'] : 'Not set'),
                      ] else ...[
                        const Divider(height: 1, indent: 40),
                        _infoRow(Icons.favorite_outline, 'Preferences',
                          user?['dress_preferences']?.isNotEmpty == true
                            ? user!['dress_preferences'] : 'None set'),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false).clearUser();
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Delete account
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Delete Account',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20))),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1B5E20), size: 20),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
            color: Color(0xFF8E8E93), fontSize: 12)),
          Text(value, style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
