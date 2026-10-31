import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../auth/domain/models/user_model.dart';

/// Technicians from `user/getAllUser` (admin-only on the backend).
class TechniciansListScreen extends ConsumerStatefulWidget {
  const TechniciansListScreen({super.key});

  @override
  ConsumerState<TechniciansListScreen> createState() =>
      _TechniciansListScreenState();
}

class _TechniciansListScreenState extends ConsumerState<TechniciansListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TechnicianInfo> _filter(List<TechnicianInfo> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((tech) {
      return tech.name.toLowerCase().contains(q) ||
          tech.email.toLowerCase().contains(q) ||
          tech.mobile.contains(_searchQuery);
    }).toList();
  }

  static const Color _green = Color(0xFF125420);
  static const Color _addGreen = Color(0xFF106220);
  static const Color _badgeBg = Color(0xFFEBF0EA);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(techniciansProvider);
    final technicians = _filter(
      (async.valueOrNull ?? const <User>[])
          .map(TechnicianInfo.fromUser)
          .toList(),
    );

    Widget body;
    if (!async.hasValue && async.isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _addGreen));
    } else if (!async.hasValue && async.hasError) {
      body = _message('${async.error}', retry: true);
    } else if (technicians.isEmpty) {
      body = _message(_searchQuery.isEmpty
          ? 'No service engineers yet'
          : 'No matching service engineers');
    } else {
      body = RefreshIndicator(
        color: _addGreen,
        onRefresh: () async {
          ref.invalidate(techniciansProvider);
          await ref.read(techniciansProvider.future);
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
          itemCount: technicians.length,
          itemBuilder: (context, index) =>
              _buildTechnicianCard(technicians[index]),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.78),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 4),
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          const Text(
            'Service Engineers List',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        child: TextField(
          controller: _searchController,
          cursorColor: _addGreen,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search Service Engineers',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 24,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: _addGreen, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(TechnicianInfo technician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0D9EE),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _avatar(technician.avatarUrl),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technician.name,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: -0.51,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.more_vert,
                          color: Colors.black54,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Active badge
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: technician.isActive
                            ? _badgeBg
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: technician.isActive ? _green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            technician.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: technician.isActive ? _green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.email, 'Email',
                        technician.email.isEmpty ? '-' : technician.email),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone, 'Mobile',
                        technician.mobile.isEmpty ? '-' : technician.mobile),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person, 'Role', technician.role),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // View Tasks button (outlined green pill, full-width)
          GestureDetector(
            onTap: () {
              context.push(
                Routes.technicianTasks,
                extra: {
                  'technicianId': technician.id,
                  'technicianName': technician.name,
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF10511D), width: 1),
              ),
              child: const Center(
                child: Text(
                  'View Tasks',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF12541F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String url) {
    Widget fallback() => Image.asset(
          'assets/images/user_avatar.png',
          width: 108,
          height: 135,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 108,
              height: 135,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 48,
              ),
            );
          },
        );
    if (url.isEmpty) return fallback();
    return Image.network(
      url,
      width: 108,
      height: 135,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Widget _message(String text, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (retry)
              TextButton(
                onPressed: () => ref.invalidate(techniciansProvider),
                child: const Text('Retry', style: TextStyle(color: _addGreen)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 14),
        const SizedBox(width: 7),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: ': $value',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TechnicianInfo {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final String designation;
  final bool isActive;
  final String avatarUrl;

  TechnicianInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.designation = '',
    this.isActive = true,
    this.avatarUrl = '',
  });

  factory TechnicianInfo.fromUser(User u) => TechnicianInfo(
        id: u.id,
        name: u.name,
        email: u.email,
        mobile: u.phone,
        role: u.role.label,
        designation: u.designation ?? u.role.label,
        isActive: u.isActive,
        avatarUrl: mediaUrl(u.profilePictureUrl),
      );
}
