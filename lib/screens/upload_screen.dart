import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Ankara';
  bool _isPublic = true;
  bool _isLoading = false;
  String _error = '';

  final List<String> _categories = [
    'Ankara', 'Kaftan', 'Formal', 'Casual', 'Wedding',
    'Traditional', 'Corporate', 'Evening', 'Kids', 'Sportswear'
  ];

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a style title');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final res = await http.post(
        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/posts/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uploader_id': appState.userId,
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _selectedCategory,
          'is_public': _isPublic,
          'link_tailor': true,
          'tailor_id': appState.userId,
        }),
      );
      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Style uploaded successfully!'),
              backgroundColor: Color(0xFF1B5E20)));
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _error = 'Upload failed. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Check your internet.');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('Upload Style')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                    size: 48, color: const Color(0xFF1B5E20).withOpacity(0.4)),
                  const SizedBox(height: 8),
                  const Text('Tap to add photo',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
                  const Text('(Image upload coming soon)',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
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
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Style Title *',
                      prefixIcon: Icon(Icons.title, color: Color(0xFF1B5E20))),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined, color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _categories.map((cat) {
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Make public',
                    style: TextStyle(fontSize: 15, color: Color(0xFF1C1C1E))),
                  Switch(
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    activeColor: const Color(0xFF1B5E20),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _upload,
                child: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('UPLOAD STYLE'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
