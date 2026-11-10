import 'dart:math';

import 'package:flutter/material.dart';

/// Shows a "Book a Repair" dialog.
///
/// Collects the booking user's name, phone (mandatory) and optional email,
/// lets them pick the equipment and service, and issues a booking token.
Future<void> showBookRepairDialog(
  BuildContext context, {
  String? technicianName,
  String? technicianImage,
  String? technicianPhone,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _BookRepairDialog(),
  );
}

class _BookRepairDialog extends StatefulWidget {
  const _BookRepairDialog();

  @override
  State<_BookRepairDialog> createState() => _BookRepairDialogState();
}

class _BookRepairDialogState extends State<_BookRepairDialog> {
  static const _services = [
    'Repair',
    'Maintenance',
    'Installation',
    'AMC Service',
    'Emergency Repair',
  ];

  static const _equipment = [
    'Range / Oven',
    'Refrigerator',
    'Microwave',
    'Dishwasher',
    'Hood / Ventilation',
    'Mixer',
    'Fryer',
    'Chiller / Freezer',
    'Ice Machine',
    'Coffee Machine',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedEquipment;
  String? _selectedService;
  String? _token;
  bool _issuing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _issueToken() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment first')),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service first')),
      );
      return;
    }
    setState(() => _issuing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final token = 'EG-${100000 + Random().nextInt(900000)}';
    setState(() {
      _token = token;
      _issuing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 420 ? width - 32 : 400.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _token == null ? _buildForm() : _buildSuccess(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book a Repair',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          // User details
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name *',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select equipment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedEquipment,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
            ),
            hint: const Text('Choose equipment'),
            items: _equipment
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selectedEquipment = v),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a service',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedService,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7E6DA)),
              ),
            ),
            hint: const Text('Choose a service'),
            items: _services
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedService = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _issuing ? null : _issueToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF106220),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _issuing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Get Token',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF106220),
          size: 56,
        ),
        const SizedBox(height: 12),
        const Text(
          'Booking confirmed!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your service token is',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF5C6B60),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F6EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF106220)),
          ),
          child: Text(
            _token!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFF106220),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$name · $_selectedEquipment · $_selectedService',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5C6B60),
          ),
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5C6B60),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          phone,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5C6B60),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              final overlay = Overlay.of(context);
              final entry = OverlayEntry(
                builder: (ctx) => Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8,),
                        decoration: BoxDecoration(
                          color: const Color(0xFF106220),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Booking successful!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              overlay.insert(entry);
              Future.delayed(const Duration(seconds: 2), entry.remove);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF106220),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
