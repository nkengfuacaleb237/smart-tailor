import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/ai_service.dart';

const _baseLooks = 'https://smart-tailor-backend-mi4z.onrender.com';

class TailorLooksScreen extends StatefulWidget {
  const TailorLooksScreen({super.key});
  @override
  State<TailorLooksScreen> createState() => _TailorLooksScreenState();
}

class _TailorLooksScreenState extends State<TailorLooksScreen> {
  List _customers = [];
  List _posts = [];
  bool _loadingCustomers = true;
  bool _loadingPosts = true;
  Map? _selectedCustomer;
  Map? _selectedPost;
  File? _customerPhoto;
  Map<String, String>? _result;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final cRes = await http.get(Uri.parse('$_baseLooks/api/tailor-customers/$tailorId'));
      final pRes = await http.get(Uri.parse('$_baseLooks/api/posts/'));
      if (!mounted) return;
      setState(() {
        _customers = jsonDecode(cRes.body);
        final allPosts = jsonDecode(pRes.body) as List;
        _posts = allPosts
          .where((p) => p['uploader_id'] == tailorId || 
            (p['tailors'] as List? ?? []).any((t) => t['id'] == tailorId))
          .toList();
        _loadingCustomers = false;
        _loadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingCustomers = false; _loadingPosts = false; });
    }
  }

  Future<void> _pickCustomerPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Customer Photo', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt_outlined, color: Color(0xFF1B5E20))),
              title: const Text('Take a photo'),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library_outlined, color: Color(0xFF1B5E20))),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Pick an existing photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() { _customerPhoto = File(picked.path); _result = null; });
  }

  Future<void> _generate() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer'))); return;
    }
    if (_selectedPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a dress style'))); return;
    }
    if (_customerPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo of the customer'))); return;
    }
    final dressImageUrl = _selectedPost!['image_url'] ?? '';
    if (dressImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This dress has no image'))); return;
    }
    setState(() { _generating = true; _result = null; });
    try {
      final result = await AiService.tryOn(personPhoto: _customerPhoto!, dressImageUrl: dressImageUrl);
      if (!mounted) return;
      setState(() { _result = result; _generating = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Looks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Show customers how they will look in your styles', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
              const SizedBox(height: 20),

              // Step 1 — Select Customer
              _stepCard(step: '1', title: 'Select Customer',
                child: _loadingCustomers
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                  : _customers.isEmpty
                    ? const Text('No customers yet. Add them in your dashboard.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13))
                    : Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _customers.map<Widget>((c) {
                          final selected = _selectedCustomer?['id'] == c['id'];
                          return GestureDetector(
                            onTap: () => setState(() { _selectedCustomer = c; _customerPhoto = null; _result = null; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF1B5E20) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? const Color(0xFF1B5E20) : const Color(0xFFE5E5EA))),
                              child: Text(c['name'] ?? '',
                                style: TextStyle(color: selected ? Colors.white : const Color(0xFF3A3A3C),
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // Step 2 — Upload customer photo
              _stepCard(step: '2', title: 'Customer Photo',
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _selectedCustomer != null ? _pickCustomerPhoto : null,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1B5E20), width: 1.5)),
                        child: _customerPhoto != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(11),
                              child: Image.file(_customerPhoto!, fit: BoxFit.cover))
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                color: _selectedCustomer != null ? const Color(0xFF1B5E20) : const Color(0xFFAAAAAA), size: 28),
                              const SizedBox(height: 4),
                              Text('Upload', style: TextStyle(
                                color: _selectedCustomer != null ? const Color(0xFF1B5E20) : const Color(0xFFAAAAAA), fontSize: 11)),
                            ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedCustomer == null ? 'Select a customer first'
                          : _customerPhoto != null ? 'Photo uploaded for ${_selectedCustomer!['name']}'
                          : 'Upload a full-body photo of ${_selectedCustomer!['name']}',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Step 3 — Select dress
              _stepCard(step: '3', title: 'Select Dress Style',
                child: _loadingPosts
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                  : _posts.isEmpty
                    ? const Text('No dress styles uploaded yet.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13))
                    : Column(
                        children: _posts.map<Widget>((p) {
                          final selected = _selectedPost?['id'] == p['id'];
                          return GestureDetector(
                            onTap: () => setState(() { _selectedPost = p; _result = null; }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? const Color(0xFF1B5E20) : const Color(0xFFE5E5EA))),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (p['image_url'] ?? '').isNotEmpty
                                    ? Image.network(p['image_url'], width: 48, height: 48, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 48, height: 48,
                                          color: const Color(0xFFE8F5E9),
                                          child: const Icon(Icons.checkroom_outlined, color: Color(0xFF1B5E20), size: 20)))
                                    : Container(width: 48, height: 48, color: const Color(0xFFE8F5E9),
                                        child: const Icon(Icons.checkroom_outlined, color: Color(0xFF1B5E20), size: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                                    color: selected ? const Color(0xFF1B5E20) : const Color(0xFF1C1C1E))),
                                  Text(p['category'] ?? '', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                ])),
                                if (selected) const Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 20),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 20),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_generating ? 'Analysing...' : 'Generate Style Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),

              // Result
              if (_result != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Image result (Fashn.ai)
                    if (_result!['imageUrl'] != null && _result!['imageUrl']!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(_result!['imageUrl']!, width: double.infinity, height: 350, fit: BoxFit.cover),
                      ),
                    // Text result (Gemini)
                    if (_result!['description'] != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1B5E20)),
                            SizedBox(width: 6),
                            Text('AI Style Report', style: TextStyle(color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                          const SizedBox(height: 8),
                          Text('${_selectedCustomer!['name']} in ${_selectedPost!['title']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1C1C1E))),
                          const SizedBox(height: 8),
                          Text(_result!['description']!,
                            style: const TextStyle(color: Color(0xFF3A3A3C), fontSize: 13, height: 1.6)),
                        ]),
                      ),
                  ]),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard({required String step, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 24, height: 24,
            decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle),
            child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1C1C1E))),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
