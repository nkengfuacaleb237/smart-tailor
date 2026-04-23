import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';

const _base = 'https://smart-tailor-backend-bzpu.onrender.com';

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
    setState(() => _loadingCustomers = true);
    try {
      final res = await http.get(Uri.parse('$_base/api/tailor-customers/'));
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

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
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
            const Text('Add Customer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E))),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1B5E20)))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await http.post(
                    Uri.parse('$_base/api/tailor-customers/'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'tailor_id': tailorId,
                      'name': nameCtrl.text,
                      'phone': phoneCtrl.text,
                      'email': emailCtrl.text,
                    }),
                  );
                  Navigator.pop(ctx);
                  _fetchCustomers();
                },
                child: const Text('SAVE CUSTOMER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map order, bool isPending) {
    return Container(
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
                radius: 20,
                child: Text((order['customer_name'] ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['customer_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 15, color: Color(0xFF1C1C1E))),
                    Text(order['post_title'] ?? '',
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                    ? const Color(0xFFFFF3E0)
                    : order['status'] == 'completed'
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order['status'] ?? '',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isPending
                      ? Colors.orange
                      : order['status'] == 'completed'
                        ? const Color(0xFF1B5E20)
                        : Colors.red)),
              ),
            ],
          ),
          if ((order['note'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_outlined, size: 14, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(order['note'],
                      style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3C))),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: const Color(0xFFE5E5EA)),
          const SizedBox(height: 16),
          Text(message,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
        ],
      ),
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
                    onTap: _showAddCustomerDialog,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1B5E20),
                unselectedLabelColor: const Color(0xFF8E8E93),
                indicatorColor: const Color(0xFF1B5E20),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                      ],
                    ),
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
                  // Pending orders
                  _loadingOrders
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _pending.isEmpty
                      ? _buildEmptyState('No pending orders', Icons.inbox_outlined)
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pending.length,
                            itemBuilder: (ctx, i) => _buildOrderCard(_pending[i], true),
                          ),
                        ),
                  // History
                  _loadingOrders
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _history.isEmpty
                      ? _buildEmptyState('No order history yet', Icons.history_outlined)
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _history.length,
                            itemBuilder: (ctx, i) => _buildOrderCard(_history[i], false),
                          ),
                        ),
                  // Customers
                  _loadingCustomers
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : _customers.isEmpty
                      ? _buildEmptyState('No customers yet.\nTap + to add one.', Icons.people_outline)
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                    onPressed: () async {
                                      await http.delete(
                                        Uri.parse('$_base/api/tailor-customers/${c['id']}'));
                                      _fetchCustomers();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
