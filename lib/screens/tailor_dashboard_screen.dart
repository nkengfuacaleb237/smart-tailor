import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'camera_measurement_screen.dart';

const _base = 'https://smart-tailor-backend-mi4z.onrender.com';

class TailorDashboardScreen extends StatefulWidget {
  const TailorDashboardScreen({super.key});

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _pending = [], _history = [], _customers = [];
  bool _loadingOrders = true, _loadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
    setState(() => _loadingOrders = true);
    try {
      final res = await http.get(Uri.parse('$_base/api/orders/tailor/$tailorId'));
      final all = List.from(jsonDecode(res.body));
      setState(() {
        _pending = all.where((o) => o['status'] == 'pending').toList();
        _history = all.where((o) => o['status'] != 'pending').toList();
        _loadingOrders = false;
      });
    } catch (e) {
      setState(() => _loadingOrders = false);
    }
  }

  Future<void> _fetchCustomers() async {
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
    setState(() => _loadingCustomers = true);
    try {
      final res = await http.get(Uri.parse('$_base/api/tailor-customers/$tailorId'));
      setState(() {
        _customers = jsonDecode(res.body);
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() => _loadingCustomers = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    await http.patch(
      Uri.parse('$_base/api/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    _fetchOrders();
  }

  void _showOrderDetails(Map order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['post_title'] ?? '',
                          style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                        Text('Order from ${order['customer_name']}',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                      ],
                    ),
                  ),
                  _statusBadge(order['status']),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Order Details'),
              _detailCard([
                if ((order['budget'] ?? 0) > 0)
                  _detailRow(Icons.payments_outlined, 'Budget',
                    '${order['budget']?.toStringAsFixed(0)} FCFA'),
                if ((order['post_price'] ?? 0) > 0)
                  _detailRow(Icons.sell_outlined, 'Style Price',
                    '${order['post_price']?.toStringAsFixed(0)} FCFA'),
                if ((order['location'] ?? '').isNotEmpty)
                  _detailRow(Icons.location_on_outlined, 'Location', order['location']),
                if ((order['color_preference'] ?? '').isNotEmpty)
                  _detailRow(Icons.palette_outlined, 'Color', order['color_preference']),
                if ((order['style_preference'] ?? '').isNotEmpty)
                  _detailRow(Icons.tune_outlined, 'Style Pref', order['style_preference']),
                if ((order['note'] ?? '').isNotEmpty)
                  _detailRow(Icons.notes_outlined, 'Note', order['note']),
              ]),
              if ((order['chest'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                _sectionTitle('Customer Measurements'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _measureChip('Chest', order['chest']),
                          _measureChip('Waist', order['waist']),
                          _measureChip('Hips', order['hips']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _measureChip('Shoulder', order['shoulder']),
                          _measureChip('Sleeve', order['sleeve']),
                          _measureChip('Inseam', order['inseam']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (order['status'] == 'pending') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'cancelled');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                        child: const Text('Accept Order'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateOrderStatus(order['id'], 'completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    child: const Text('Mark as Completed'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 15,
      fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
  );

  Widget _detailCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
        Expanded(child: Text(value,
          style: const TextStyle(color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    ),
  );

  Widget _measureChip(String label, dynamic value) => Column(
    children: [
      Text('${value ?? 0}cm',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
          color: Color(0xFF1B5E20))),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
    ],
  );

  Widget _statusBadge(String? status) {
    Color bg, fg;
    switch (status) {
      case 'accepted': bg = const Color(0xFFE3F2FD); fg = Colors.blue; break;
      case 'completed': bg = const Color(0xFFE8F5E9); fg = const Color(0xFF1B5E20); break;
      case 'cancelled': bg = const Color(0xFFFFEBEE); fg = Colors.red; break;
      default: bg = const Color(0xFFFFF3E0); fg = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status ?? 'pending',
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  void _showAddCustomerDialog({Map? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Customer' : 'Add Customer',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E))),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  if (isEdit) {
                    await http.put(
                      Uri.parse('$_base/api/tailor-customers/${existing['id']}'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      }),
                    );
                  } else {
                    await http.post(
                      Uri.parse('$_base/api/tailor-customers/'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'tailor_id': tailorId,
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      }),
                    );
                  }
                  Navigator.pop(ctx);
                  _fetchCustomers();
                },
                child: Text(isEdit ? 'SAVE CHANGES' : 'SAVE CUSTOMER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeasurementOptions(Map customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Measure ${customer['name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E))),
            const SizedBox(height: 8),
            const Text('Choose measurement method',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CameraMeasurementScreen(
                    tailorCustomerId: customer['id'])));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Camera Scan',
                            style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Auto-detect body measurements',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _showManualMeasurement(customer);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA))),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.straighten_outlined,
                        color: Color(0xFF1B5E20), size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manual Entry',
                            style: TextStyle(color: Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Type measurements manually',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF8E8E93), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showManualMeasurement(Map customer, {Map? existing}) {
    final chestCtrl = TextEditingController(text: existing?['chest']?.toString() ?? '');
    final waistCtrl = TextEditingController(text: existing?['waist']?.toString() ?? '');
    final hipsCtrl = TextEditingController(text: existing?['hips']?.toString() ?? '');
    final shoulderCtrl = TextEditingController(text: existing?['shoulder']?.toString() ?? '');
    final sleeveCtrl = TextEditingController(text: existing?['sleeve']?.toString() ?? '');
    final inseamCtrl = TextEditingController(text: existing?['inseam']?.toString() ?? '');
    final labelCtrl = TextEditingController(text: existing?['label'] ?? 'Manual Entry');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Measurements' : 'Add Measurements for ${customer['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              const Text('All measurements in cm',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. Suit, Wedding dress)')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: chestCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Chest'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: waistCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Waist'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: hipsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hips'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: shoulderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Shoulder'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: sleeveCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sleeve'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: inseamCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Inseam'))),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final body = jsonEncode({
                      'chest': double.tryParse(chestCtrl.text) ?? 0,
                      'waist': double.tryParse(waistCtrl.text) ?? 0,
                      'hips': double.tryParse(hipsCtrl.text) ?? 0,
                      'shoulder': double.tryParse(shoulderCtrl.text) ?? 0,
                      'sleeve': double.tryParse(sleeveCtrl.text) ?? 0,
                      'inseam': double.tryParse(inseamCtrl.text) ?? 0,
                      'label': labelCtrl.text.trim(),
                    });
                    if (isEdit) {
                      await http.put(
                        Uri.parse('$_base/api/tailor-customers/measurements/${existing['id']}'),
                        headers: {'Content-Type': 'application/json'},
                        body: body,
                      );
                    } else {
                      await http.post(
                        Uri.parse('$_base/api/tailor-customers/${customer['id']}/measurements'),
                        headers: {'Content-Type': 'application/json'},
                        body: body,
                      );
                    }
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Measurements saved!'),
                          backgroundColor: Color(0xFF1B5E20)));
                    }
                  },
                  child: Text(isEdit ? 'SAVE CHANGES' : 'SAVE MEASUREMENTS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map order) {
    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20), radius: 20,
                  child: Text((order['customer_name'] ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order['customer_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 15, color: Color(0xFF1C1C1E))),
                    Text(order['post_title'] ?? '',
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  ]),
                ),
                _statusBadge(order['status']),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if ((order['budget'] ?? 0) > 0) ...[
                  const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 4),
                  Text('Budget: ${order['budget']?.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if ((order['location'] ?? '').isNotEmpty) ...[
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 4),
                  Text(order['location'],
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Tap to view full details',
                  style: TextStyle(color: Color(0xFF1B5E20),
                    fontSize: 12, fontWeight: FontWeight.w500)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF1B5E20)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 60, color: const Color(0xFFE5E5EA)),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('Dashboard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddCustomerDialog(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1B5E20),
                unselectedLabelColor: const Color(0xFF8E8E93),
                indicatorColor: const Color(0xFF1B5E20),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Pending'),
                      if (_pending.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10)),
                          child: Text('${_pending.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ]),
                  ),
                  const Tab(text: 'History'),
                  const Tab(text: 'Customers'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _loadingOrders
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _pending.isEmpty
                      ? _buildEmptyState('No pending orders', Icons.inbox_outlined)
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pending.length,
                            itemBuilder: (ctx, i) => _buildOrderCard(_pending[i]),
                          )),
                  _loadingOrders
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _history.isEmpty
                      ? _buildEmptyState('No order history yet', Icons.history_outlined)
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _history.length,
                            itemBuilder: (ctx, i) => _buildOrderCard(_history[i]),
                          )),
                  _loadingCustomers
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _customers.isEmpty
                      ? _buildEmptyState('No customers yet.\nTap + to add one.',
                          Icons.people_outline)
                      : RefreshIndicator(
                          onRefresh: _fetchCustomers,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _customers.length,
                            itemBuilder: (ctx, i) {
                              final c = _customers[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    child: Text((c['name'] ?? 'C')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(c['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600,
                                      color: Color(0xFF1C1C1E))),
                                  subtitle: Text(c['phone'] ?? '',
                                    style: const TextStyle(color: Color(0xFF8E8E93))),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(
                                      icon: const Icon(Icons.straighten_outlined,
                                        color: Color(0xFF1B5E20), size: 20),
                                      onPressed: () => _showMeasurementOptions(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF1B5E20), size: 20),
                                      onPressed: () => _showAddCustomerDialog(existing: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                      onPressed: () async {
                                        await http.delete(Uri.parse(
                                          '$_base/api/tailor-customers/${c['id']}'));
                                        _fetchCustomers();
                                      },
                                    ),
                                  ]),
                                ),
                              );
                            },
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
