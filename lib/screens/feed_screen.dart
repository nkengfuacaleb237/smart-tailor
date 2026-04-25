import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/style_card.dart';
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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final url = _selectedCategory == 'All'
        ? 'https://smart-tailor-backend-mi4z.onrender.com/api/posts/'
        : 'https://smart-tailor-backend-mi4z.onrender.com/api/posts/?category=$_selectedCategory';
      final res = await http.get(Uri.parse(url));
      if (!mounted) return;
      setState(() {
        _posts = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(Map post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Style'),
        content: Text('Delete this style? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await http.delete(Uri.parse(
      'https://smart-tailor-backend-mi4z.onrender.com/api/posts/${post["id"]}'));
    _fetchPosts();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Style deleted'), backgroundColor: Colors.red));
  }

  void _showEditSheet(Map post) {
    final titleCtrl = TextEditingController(text: post['title'] ?? '');
    final descCtrl = TextEditingController(text: post['description'] ?? '');
    final priceCtrl = TextEditingController(text: post['price']?.toString() ?? '');
    final daysCtrl = TextEditingController(text: post['estimated_days']?.toString() ?? '');
    String selectedCategory = post['category'] ?? 'Ankara';
    final categories = ['Ankara', 'Kaftan', 'Formal', 'Casual', 'Wedding', 'Traditional', 'Corporate', 'Evening'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Style', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title',
                    prefixIcon: Icon(Icons.title, color: Color(0xFF1B5E20)))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined, color: Color(0xFF1B5E20)))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModal(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (FCFA)',
                      prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF1B5E20))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Days',
                      prefixIcon: Icon(Icons.schedule_outlined, color: Color(0xFF1B5E20))))),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await http.patch(
                        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/posts/${post["id"]}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'category': selectedCategory,
                          'price': double.tryParse(priceCtrl.text) ?? 0,
                          'estimated_days': int.tryParse(daysCtrl.text) ?? 7,
                        }),
                      );
                      Navigator.pop(ctx);
                      _fetchPosts();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Style updated!'),
                          backgroundColor: Color(0xFF1B5E20)));
                    },
                    child: const Text('SAVE CHANGES'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      Text('Hello, ${appState.currentUser?['name']?.split(' ')[0] ?? ''}',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
                      const Text('Discover Styles',
                        style: TextStyle(color: Color(0xFF1C1C1E),
                          fontSize: 22, fontWeight: FontWeight.w700,
                          letterSpacing: -0.5)),
                    ],
                  ),
                  const Spacer(),
                  if (appState.isTailor)
                    GestureDetector(
                      onTap: () async {
                        final uploaded = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const UploadScreen()));
                        if (uploaded == true) _fetchPosts();
                      },
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
                          const Text('No styles yet',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Tailors will upload styles here',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
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
                        itemBuilder: (ctx, i) => StyleCard(
                          post: _posts[i],
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              DressDetailScreen(post: _posts[i]))),
                          onEdit: appState.isTailor && _posts[i]['uploader_id'] == appState.userId
                            ? () => _showEditSheet(_posts[i]) : null,
                          onDelete: appState.isTailor && _posts[i]['uploader_id'] == appState.userId
                            ? () => _deletePost(_posts[i]) : null,
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
