import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/ai_service.dart';
import 'dress_detail_screen.dart';

const _base = 'https://smart-tailor-backend-mi4z.onrender.com';

class MyLooksScreen extends StatefulWidget {
  const MyLooksScreen({super.key});
  @override
  State<MyLooksScreen> createState() => _MyLooksScreenState();
}

class _MyLooksScreenState extends State<MyLooksScreen> {
  List _favorites = [];
  bool _isLoading = true;
  File? _selfie;
  final Map<int, Map<String, String>> _tryOnResults = {};
  final Map<int, bool> _generating = {};

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.get(Uri.parse('$_base/api/posts/favorites/$userId'));
      if (!mounted) return;
      setState(() {
        _favorites = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickSelfie() async {
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
            const Text('Upload Your Photo', style: TextStyle(
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
    final picked = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selfie = File(picked.path));
  }

  Future<void> _tryOn(Map post) async {
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please take a selfie first'),
        backgroundColor: Color(0xFF1B5E20)));
      return;
    }
    final dressImageUrl = post['image_url'] ?? '';
    if (dressImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This dress has no image yet')));
      return;
    }
    final postId = post['id'] as int;
    setState(() => _generating[postId] = true);
    try {
      final result = await AiService.tryOn(
        personPhoto: _selfie!,
        dressImageUrl: dressImageUrl,
      );
      if (!mounted) return;
      setState(() {
        _tryOnResults[postId] = result;
        _generating[postId] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating[postId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Try-on failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('My Looks',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('AI style reports for your saved dresses',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                ],
              ),
            ),

            // Selfie section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickSelfie,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B5E20), width: 1.5)),
                      child: _selfie != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(_selfie!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                color: Color(0xFF1B5E20), size: 24),
                              SizedBox(height: 4),
                              Text('Photo', style: TextStyle(
                                color: Color(0xFF1B5E20), fontSize: 11)),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selfie != null
                            ? 'Photo ready! Tap a dress to get your AI style report.'
                            : 'Upload your photo to get personalized style reports',
                          style: const TextStyle(fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E), fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickSelfie,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _selfie != null ? 'Change Photo' : 'Upload Photo',
                              style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF1B5E20)))
                : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.favorite_outline, size: 60,
                            color: Color(0xFFE5E5EA)),
                          SizedBox(height: 16),
                          Text('No saved styles yet',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Heart styles from the feed to try them on here',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                        ],
                      ))
                  : RefreshIndicator(
                      onRefresh: _fetchFavorites,
                      color: const Color(0xFF1B5E20),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                        itemCount: _favorites.length,
                        itemBuilder: (ctx, i) {
                          final post = _favorites[i];
                          final postId = post['id'] as int;
                          final isGenerating = _generating[postId] ?? false;
                          final result = _tryOnResults[postId];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (post['image_url'] ?? '').isNotEmpty
                                      ? Image.network(post['image_url'],
                                          width: 50, height: 50, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 50, height: 50,
                                            color: const Color(0xFFE8F5E9),
                                            child: const Icon(Icons.checkroom_outlined,
                                              color: Color(0xFF1B5E20))))
                                      : Container(width: 50, height: 50,
                                          color: const Color(0xFFE8F5E9),
                                          child: const Icon(Icons.checkroom_outlined,
                                            color: Color(0xFF1B5E20))),
                                  ),
                                  title: Text(post['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600,
                                      fontSize: 15, color: Color(0xFF1C1C1E))),
                                  subtitle: Text(
                                    '${post['category'] ?? ''}${(post['price'] ?? 0) > 0 ? ' · ${post['price']?.toStringAsFixed(0)} FCFA' : ''}',
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                  trailing: GestureDetector(
                                    onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) =>
                                        DressDetailScreen(post: post))),
                                    child: const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Color(0xFF8E8E93))),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: isGenerating
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(12)),
                                        child: const Column(children: [
                                          CircularProgressIndicator(
                                            color: Color(0xFF1B5E20), strokeWidth: 2),
                                          SizedBox(height: 10),
                                          Text('AI is analysing your style...',
                                            style: TextStyle(color: Color(0xFF1B5E20),
                                              fontSize: 13)),
                                        ]))
                                    : result != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Show image result if Fashn.ai
                                            if (result['imageUrl'] != null &&
                                                result['imageUrl']!.isNotEmpty)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(result['imageUrl']!,
                                                  width: double.infinity,
                                                  height: 280, fit: BoxFit.cover),
                                              ),
                                            // Show text description if Gemini
                                            if (result['description'] != null)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(12)),
                                                child: Column(
                                                  crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                  children: [
                                                    const Row(children: [
                                                      Icon(Icons.auto_awesome,
                                                        size: 14, color: Color(0xFF1B5E20)),
                                                      SizedBox(width: 6),
                                                      Text('Your AI Style Report',
                                                        style: TextStyle(
                                                          color: Color(0xFF1B5E20),
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13)),
                                                    ]),
                                                    const SizedBox(height: 8),
                                                    Text(result['description']!,
                                                      style: const TextStyle(
                                                        color: Color(0xFF3A3A3C),
                                                        fontSize: 13, height: 1.6)),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _tryOn(post),
                                              child: const Text('Regenerate',
                                                style: TextStyle(
                                                  color: Color(0xFF8E8E93),
                                                  fontSize: 11,
                                                  decoration: TextDecoration.underline)),
                                            ),
                                          ])
                                      : SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _tryOn(post),
                                            icon: const Icon(Icons.auto_awesome, size: 16),
                                            label: const Text('Get My Style Report'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1B5E20),
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12))),
                                          )),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
