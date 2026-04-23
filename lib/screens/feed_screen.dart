import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'dress_detail_screen.dart';
import 'upload_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List _posts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Ankara', 'Kaftan', 'Formal', 'Casual',
    'Wedding', 'Traditional', 'Corporate', 'Evening'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final url = _selectedCategory == 'All'
        ? 'https://smart-tailor-backend-bzpu.onrender.com/api/posts/'
        : 'https://smart-tailor-backend-bzpu.onrender.com/api/posts/?category=';
      final res = await http.get(Uri.parse(url));
      setState(() {
        _posts = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
                      const Text('Discover Styles',
                        style: TextStyle(color: Color(0xFF1C1C1E),
                          fontSize: 22, fontWeight: FontWeight.w700,
                          letterSpacing: -0.5)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UploadScreen())),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _fetchPosts();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1B5E20) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(cat,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF3A3A3C),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_outlined, size: 60, color: Color(0xFFE5E5EA)),
                          const SizedBox(height: 16),
                          const Text('No posts yet', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Be the first to upload a style!',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const UploadScreen())),
                            child: const Text('Upload Style'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPosts,
                      color: const Color(0xFF1B5E20),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (ctx, i) {
                          final post = _posts[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                DressDetailScreen(post: post))),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      ),
                                      child: Center(
                                        child: Icon(Icons.checkroom_outlined,
                                          size: 48,
                                          color: const Color(0xFF1B5E20).withOpacity(0.4)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(post['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1C1C1E)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(post['category'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF1B5E20),
                                              fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
