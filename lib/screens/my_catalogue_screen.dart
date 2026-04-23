import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'dress_detail_screen.dart';

class MyCatalogueScreen extends StatefulWidget {
  const MyCatalogueScreen({super.key});

  @override
  State<MyCatalogueScreen> createState() => _MyCatalogueScreenState();
}

class _MyCatalogueScreenState extends State<MyCatalogueScreen> {
  List _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.get(
        Uri.parse('https://smart-tailor-backend-bzpu.onrender.com/api/posts/favorites/$userId'));
      setState(() {
        _favorites = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text('My Catalogue',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_outline, size: 60, color: Color(0xFFE5E5EA)),
                          const SizedBox(height: 16),
                          const Text('No saved styles yet',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Heart styles from the feed to save them here',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _favorites.length,
                      itemBuilder: (ctx, i) {
                        final post = _favorites[i];
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
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.vertical(
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
                                          fontSize: 13, color: Color(0xFF1C1C1E)),
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
                                          style: const TextStyle(fontSize: 10,
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
          ],
        ),
      ),
    );
  }
}
