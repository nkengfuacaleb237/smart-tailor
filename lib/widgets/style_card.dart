import 'package:flutter/material.dart';

class StyleCard extends StatelessWidget {
  final Map post;
  final VoidCallback onTap;
  const StyleCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image_url'] ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 13, color: Color(0xFF1C1C1E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(post['category'] ?? '',
                      style: const TextStyle(fontSize: 10,
                        color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Icon(Icons.checkroom_outlined, size: 48,
          color: const Color(0xFF1B5E20).withOpacity(0.4)),
      ),
    );
  }
}
