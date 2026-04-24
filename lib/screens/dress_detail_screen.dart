import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';

const _base = 'https://smart-tailor-backend-mi4z.onrender.com';

class DressDetailScreen extends StatefulWidget {
  final Map post;
  const DressDetailScreen({super.key, required this.post});

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends State<DressDetailScreen> {
  bool _favorited = false;
  bool _ordering = false;
  List _userMeasurements = [];

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

  Future<void> _fetchMeasurements() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.get(
        Uri.parse('$_base/api/measurements/user/$userId'));
      if (mounted) setState(() => _userMeasurements = jsonDecode(res.body));
    } catch (e) {
      debugPrint('Fetch measurements error: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.post(
        Uri.parse('$_base/api/posts/${widget.post['id']}/favorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(res.body);
      setState(() => _favorited = data['favorited']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_favorited ? 'Added to catalogue!' : 'Removed from catalogue'),
            backgroundColor: const Color(0xFF1B5E20)));
      }
    } catch (e) {
      debugPrint('Favorite error: $e');
    }
  }

  void _showOrderSheet(Map tailor) {
    final appState = Provider.of<AppState>(context, listen: false);
    final budgetCtrl = TextEditingController();
    final locationCtrl = TextEditingController(
      text: appState.currentUser?['location'] ?? '');
    final colorCtrl = TextEditingController();
    final styleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    Map? _selectedMeasurement;

    final price = widget.post['price'] ?? 0;
    final days = widget.post['estimated_days'] ?? 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Place Order',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E))),
                          Text('with ${tailor['name']}',
                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        price > 0 ? '${price.toStringAsFixed(0)} FCFA' : 'Price on request',
                        style: const TextStyle(color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                if (days > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 14, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text('Estimated completion: $days days',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Your Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Your budget (FCFA)',
                    prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF1B5E20))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your location',
                    prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF1B5E20))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Color preference',
                    hintText: 'e.g. Red, Blue, Any dark color',
                    prefixIcon: Icon(Icons.palette_outlined, color: Color(0xFF1B5E20))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: styleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Style preferences (optional)',
                    hintText: 'e.g. Slim fit, Long sleeves, Round neck',
                    prefixIcon: Icon(Icons.tune_outlined, color: Color(0xFF1B5E20))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Additional notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined, color: Color(0xFF1B5E20))),
                ),
                const SizedBox(height: 20),
                const Text('Select Measurements',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E))),
                const SizedBox(height: 4),
                const Text('Choose saved measurements or proceed without',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                const SizedBox(height: 12),
                _userMeasurements.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF8E8E93), size: 16),
                          SizedBox(width: 8),
                          Text('No saved measurements. You can add them in the Measure tab.',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => _selectedMeasurement = null),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedMeasurement == null
                                ? const Color(0xFFE8F5E9) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMeasurement == null
                                  ? const Color(0xFF1B5E20) : const Color(0xFFE5E5EA)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedMeasurement == null
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                  color: const Color(0xFF1B5E20), size: 18),
                                const SizedBox(width: 8),
                                const Text('Proceed without measurements',
                                  style: TextStyle(color: Color(0xFF3A3A3C), fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        ..._userMeasurements.map((m) => GestureDetector(
                          onTap: () => setModalState(() => _selectedMeasurement = m),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedMeasurement?['id'] == m['id']
                                ? const Color(0xFFE8F5E9) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMeasurement?['id'] == m['id']
                                  ? const Color(0xFF1B5E20) : const Color(0xFFE5E5EA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _selectedMeasurement?['id'] == m['id']
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                      color: const Color(0xFF1B5E20), size: 18),
                                    const SizedBox(width: 8),
                                    Text(m['label'] ?? 'Measurement',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1C1C1E), fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _chip('Chest', m['chest']),
                                    _chip('Waist', m['waist']),
                                    _chip('Hips', m['hips']),
                                    _chip('Shoulder', m['shoulder']),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _ordering ? null : () async {
                      Navigator.pop(ctx);
                      setState(() => _ordering = true);
                      try {
                        final userId = appState.userId;
                        await http.post(
                          Uri.parse('$_base/api/orders/'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'customer_id': userId,
                            'tailor_id': tailor['id'],
                            'post_id': widget.post['id'],
                            'note': noteCtrl.text,
                            'budget': double.tryParse(budgetCtrl.text) ?? 0,
                            'location': locationCtrl.text,
                            'color_preference': colorCtrl.text,
                            'style_preference': styleCtrl.text,
                            'chest': _selectedMeasurement?['chest'] ?? 0,
                            'waist': _selectedMeasurement?['waist'] ?? 0,
                            'hips': _selectedMeasurement?['hips'] ?? 0,
                            'shoulder': _selectedMeasurement?['shoulder'] ?? 0,
                            'sleeve': _selectedMeasurement?['sleeve'] ?? 0,
                            'inseam': _selectedMeasurement?['inseam'] ?? 0,
                          }),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed successfully!'),
                              backgroundColor: Color(0xFF1B5E20)));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to place order')));
                        }
                      }
                      setState(() => _ordering = false);
                    },
                    child: _ordering
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRM ORDER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: ${value ?? 0}cm',
        style: const TextStyle(fontSize: 11, color: Color(0xFF3A3A3C))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tailors = widget.post['tailors'] as List? ?? [];
    final appState = Provider.of<AppState>(context);
    final price = widget.post['price'] ?? 0;
    final days = widget.post['estimated_days'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.post['image_url'] != null &&
                  widget.post['image_url'].toString().isNotEmpty
                ? Image.network(widget.post['image_url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8F5E9),
                      child: Center(
                        child: Icon(Icons.checkroom_outlined, size: 100,
                          color: const Color(0xFF1B5E20).withOpacity(0.3)))))
                : Container(
                    color: const Color(0xFFE8F5E9),
                    child: Center(
                      child: Icon(Icons.checkroom_outlined, size: 100,
                        color: const Color(0xFF1B5E20).withOpacity(0.3)))),
            ),
            actions: [
              if (!appState.isTailor)
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (price > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${price.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (days > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_outlined, size: 14,
                                color: Color(0xFF8E8E93)),
                              const SizedBox(width: 4),
                              Text('$days days',
                                style: const TextStyle(color: Color(0xFF8E8E93),
                                  fontSize: 13)),
                            ],
                          ),
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
                  const Text('Tap a tailor to place an order',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    radius: 22,
                                    child: Text((t['name'] ?? 'T')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w700,
                                            fontSize: 15, color: Color(0xFF1C1C1E))),
                                        if ((t['location'] ?? '').isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined,
                                                size: 12, color: Color(0xFF8E8E93)),
                                              const SizedBox(width: 2),
                                              Text(t['location'],
                                                style: const TextStyle(
                                                  color: Color(0xFF8E8E93), fontSize: 12)),
                                            ],
                                          ),
                                        if ((t['years_experience'] ?? 0) > 0)
                                          Row(
                                            children: [
                                              const Icon(Icons.workspace_premium_outlined,
                                                size: 12, color: Color(0xFF8E8E93)),
                                              const SizedBox(width: 2),
                                              Text('${t['years_experience']} yrs experience',
                                                style: const TextStyle(
                                                  color: Color(0xFF8E8E93), fontSize: 12)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if ((t['contact_info'] ?? '').isNotEmpty || (t['phone'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.chat_outlined, size: 14,
                                        color: Color(0xFF1B5E20)),
                                      const SizedBox(width: 6),
                                      Text(
                                        t['contact_info']?.isNotEmpty == true
                                          ? t['contact_info']
                                          : t['phone'] ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFF3A3A3C), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                              if (!appState.isTailor) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _showOrderSheet(t),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12)),
                                    child: const Text('Order from this Tailor',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
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
