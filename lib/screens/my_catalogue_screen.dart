import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/style_card.dart';
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
      final res = await http.get(Uri.parse(
        'https://smart-tailor-backend-mi4z.onrender.com/api/posts/favorites/$userId'));
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
                        children: const [
                          Icon(Icons.favorite_outline, size: 60, color: Color(0xFFE5E5EA)),
                          SizedBox(height: 16),
                          Text('No saved styles yet',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Heart styles from the feed to save them here',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchFavorites,
                      color: const Color(0xFF1B5E20),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _favorites.length,
                        itemBuilder: (ctx, i) => StyleCard(
                          post: _favorites[i],
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              DressDetailScreen(post: _favorites[i]))),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
