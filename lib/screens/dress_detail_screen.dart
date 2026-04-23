import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';

class DressDetailScreen extends StatefulWidget {
  final Map post;
  const DressDetailScreen({super.key, required this.post});

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends State<DressDetailScreen> {
  bool _favorited = false;

  Future<void> _toggleFavorite() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.post(
        Uri.parse('https://smart-tailor-backend-bzpu.onrender.com/api/posts//favorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(res.body);
      setState(() => _favorited = data['favorited']);
    } catch (e) {
      debugPrint('Favorite error: ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailors = widget.post['tailors'] as List? ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFE8F5E9),
                child: Center(
                  child: Icon(Icons.checkroom_outlined,
                    size: 100,
                    color: const Color(0xFF1B5E20).withOpacity(0.3)),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _favorited ? Icons.favorite : Icons.favorite_outline,
                  color: _favorited ? Colors.red : Colors.white),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.post['title'] ?? '',
                          style: const TextStyle(fontSize: 24,
                            fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.post['category'] ?? '',
                          style: const TextStyle(color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                  if ((widget.post['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(widget.post['description'],
                      style: const TextStyle(color: Color(0xFF8E8E93),
                        fontSize: 14, height: 1.6)),
                  ],
                  const SizedBox(height: 24),
                  const Text('Available Tailors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E), letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  const Text('Tailors who can sew this style',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  const SizedBox(height: 16),
                  tailors.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('No tailors linked yet',
                            style: TextStyle(color: Color(0xFF8E8E93))),
                        ),
                      )
                    : Column(
                        children: tailors.map<Widget>((t) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1B5E20),
                                child: Text((t['name'] ?? 'T')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600,
                                        fontSize: 15, color: Color(0xFF1C1C1E))),
                                    if ((t['location'] ?? '').isNotEmpty)
                                      Text(t['location'],
                                        style: const TextStyle(color: Color(0xFF8E8E93),
                                          fontSize: 13)),
                                    if ((t['years_experience'] ?? 0) > 0)
                                      Text(' years experience',
                                        style: const TextStyle(color: Color(0xFF8E8E93),
                                          fontSize: 12)),
                                  ],
                                ),
                              ),
                              if ((t['contact_info'] ?? '').isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Contact: ')));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B5E20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Contact',
                                      style: TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ],
                          ),
                        )).toList(),
                      ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
