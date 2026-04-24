import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '7');
  String _selectedCategory = 'Ankara';
  bool _isPublic = true;
  bool _isLoading = false;
  String _error = '';
  File? _imageFile;
  String? _imageUrl;

  final List<String> _categories = [
    'Ankara', 'Kaftan', 'Formal', 'Casual', 'Wedding',
    'Traditional', 'Corporate', 'Evening', 'Kids', 'Sportswear'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/ds9mzohwn/image/upload'),
      );
      request.fields['upload_preset'] = 'smart-tailor';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      return data['secure_url'];
    } catch (e) {
      debugPrint('Cloudinary error: $e');
      return null;
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a style title');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a price in FCFA');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      if (_imageFile != null) {
        _imageUrl = await _uploadToCloudinary(_imageFile!);
      }
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
          'image_url': _imageUrl ?? '',
          'price': double.tryParse(_priceCtrl.text) ?? 0,
          'estimated_days': int.tryParse(_daysCtrl.text) ?? 7,
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
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('Upload Style')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: const Color(0xFF1B5E20).withOpacity(0.5)),
                        const SizedBox(height: 8),
                        const Text('Tap to select photo',
                          style: TextStyle(color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('JPG, PNG supported',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                      ],
                    ),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price (FCFA) *',
                            prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF1B5E20))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _daysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Days to complete',
                            prefixIcon: Icon(Icons.schedule_outlined, color: Color(0xFF1B5E20))),
                        ),
                      ),
                    ],
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Posted as: ${appState.currentUser?['name'] ?? ''}\nLocation: ${appState.currentUser?['location'] ?? 'Not set'}\nContact: ${appState.currentUser?['contact_info'] ?? 'Not set'}',
                      style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _upload,
                child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Uploading...'),
                      ])
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
