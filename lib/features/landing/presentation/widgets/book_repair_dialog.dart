import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../data/guest_repair_bookings_repository.dart';

/// Shows a "Book a Repair" dialog.
///
/// Collects the booking user's details and displays the reference returned
/// after submitting the enquiry.
Future<void> showBookRepairDialog(
  BuildContext context, {
  String? technicianName,
  String? technicianImage,
  String? technicianPhone,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Book a Repair',
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (_, __, ___) => const _BookRepairDialog(),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _BookRepairDialog extends ConsumerStatefulWidget {
  const _BookRepairDialog();

  @override
  ConsumerState<_BookRepairDialog> createState() => _BookRepairDialogState();
}

class _BookRepairDialogState extends ConsumerState<_BookRepairDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  List<GuestRepairEquipment> _equipment = const [];
  List<String> _services = const [];
  GuestRepairEquipment? _selectedEquipment;
  String? _selectedService;
  String? _reference;
  String? _idempotencyKey;
  String? _equipmentError;
  String? _servicesError;
  bool _loadingEquipment = true;
  bool _loadingServices = true;
  bool _issuing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEquipment());
    unawaited(_loadServices());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _loadingEquipment = true;
      _equipmentError = null;
    });
    try {
      final equipment =
          await ref.read(guestRepairBookingsRepositoryProvider).getEquipment();
      if (!mounted) return;
      setState(() {
        _equipment = equipment;
        _loadingEquipment = false;
        if (_selectedEquipment != null) {
          final selected = equipment.where(
            (item) => item.id == _selectedEquipment!.id,
          );
          _selectedEquipment = selected.isEmpty ? null : selected.first;
        }
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      _reportUnexpectedError(error, stackTrace);
      setState(() {
        _loadingEquipment = false;
        _equipmentError = _errorMessage(error, 'Unable to load equipment.');
      });
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _servicesError = null;
    });
    try {
      final services =
          await ref.read(guestRepairBookingsRepositoryProvider).getServices();
      if (!mounted) return;
      setState(() {
        _services = services;
        _loadingServices = false;
        if (_selectedService != null && !services.contains(_selectedService)) {
          _selectedService = null;
        }
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      _reportUnexpectedError(error, stackTrace);
      setState(() {
        _loadingServices = false;
        _servicesError = _errorMessage(error, 'Unable to load services.');
      });
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is FailureException) return error.failure.displayMessage;
    if (error is RepositoryException) return error.message;
    return fallback;
  }

  void _reportUnexpectedError(Object error, StackTrace stackTrace) {
    if (error is FailureException || error is RepositoryException) return;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Book a Repair popup',
      ),
    );
  }

  String _newIdempotencyKey() {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    final random = Random.secure();
    return List.generate(
      32,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  Future<void> _submitEnquiry() async {
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

    final idempotencyKey = _idempotencyKey ?? _newIdempotencyKey();
    setState(() {
      _issuing = true;
      _idempotencyKey = idempotencyKey;
    });
    try {
      final response =
          await ref.read(guestRepairBookingsRepositoryProvider).submitBooking(
                name: _nameController.text,
                phone: _phoneController.text,
                email: _emailController.text,
                equipmentId: _selectedEquipment!.id,
                service: _selectedService!,
                idempotencyKey: idempotencyKey,
              );
      if (!mounted) return;
      setState(() => _reference = response.reference);
    } catch (error, stackTrace) {
      if (!mounted) return;
      _reportUnexpectedError(error, stackTrace);
      final message = _errorMessage(error, 'Unable to submit your enquiry.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
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
          child: _reference == null ? _buildForm() : _buildSuccess(),
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
            onChanged: (_) => _idempotencyKey = null,
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
            onChanged: (_) => _idempotencyKey = null,
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
            onChanged: (_) => _idempotencyKey = null,
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
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _selectedEquipment?.id,
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
              suffixIcon: _loadingEquipment
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _equipmentError != null
                      ? IconButton(
                          tooltip:
                              '$_equipmentError Retry equipment loading',
                          onPressed: () => unawaited(_loadEquipment()),
                          icon: const Icon(Icons.refresh),
                        )
                      : null,
            ),
            hint: Text(
              _loadingEquipment
                  ? 'Loading equipment...'
                  : _equipmentError != null
                      ? 'Equipment unavailable'
                      : _equipment.isEmpty
                          ? 'No equipment available'
                          : 'Choose equipment',
            ),
            items: _equipment
                .map(
                  (equipment) => DropdownMenuItem<int>(
                    value: equipment.id,
                    child: Text(equipment.name),
                  ),
                )
                .toList(),
            onChanged: _loadingEquipment ||
                    _equipmentError != null ||
                    _equipment.isEmpty
                ? null
                : (id) {
                    final selected =
                        _equipment.where((equipment) => equipment.id == id);
                    setState(() {
                      _selectedEquipment =
                          selected.isEmpty ? null : selected.first;
                      _idempotencyKey = null;
                    });
                  },
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
            isExpanded: true,
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
              suffixIcon: _loadingServices
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _servicesError != null
                      ? IconButton(
                          tooltip: '$_servicesError Retry services loading',
                          onPressed: () => unawaited(_loadServices()),
                          icon: const Icon(Icons.refresh),
                        )
                      : null,
            ),
            hint: Text(
              _loadingServices
                  ? 'Loading services...'
                  : _servicesError != null
                      ? 'Services unavailable'
                      : _services.isEmpty
                          ? 'No services available'
                          : 'Choose a service',
            ),
            items: _services
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: _loadingServices ||
                    _servicesError != null ||
                    _services.isEmpty
                ? null
                : (v) => setState(() {
                      _selectedService = v;
                      _idempotencyKey = null;
                    }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _issuing ? null : _submitEnquiry,
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
          'Enquiry submitted!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your booking reference is',
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
            _reference!,
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
          '$name · ${_selectedEquipment?.name ?? ''} · $_selectedService',
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
                          'Enquiry submitted successfully!',
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
