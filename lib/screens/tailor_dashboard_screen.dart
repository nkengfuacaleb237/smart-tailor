import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';

class TailorDashboardScreen extends StatefulWidget {
  const TailorDashboardScreen({super.key});

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen> {
  List _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final tailorId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.get(
        Uri.parse('https://smart-tailor-backend-bzpu.onrender.com/api/tailor-customers/'));
      setState(() {
        _customers = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
                    Uri.parse('https://smart-tailor-backend-bzpu.onrender.com/api/tailor-customers/'),
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

  Future<void> _deleteCustomer(int id) async {
    await http.delete(Uri.parse('https://smart-tailor-backend-bzpu.onrender.com/api/tailor-customers/'));
    _fetchCustomers();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Text('My Customers',
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
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _customers.isEmpty
                  ? const Center(
                      child: Text('No customers yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)))
                  : ListView.builder(
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
                              onPressed: () => _deleteCustomer(c['id']),
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
