import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';

/// Full-page AMC/company selector used by the Add User screen.
class SelectAmcScreen extends ConsumerStatefulWidget {
  const SelectAmcScreen({super.key});

  @override
  ConsumerState<SelectAmcScreen> createState() => _SelectAmcScreenState();
}

class _SelectAmcScreenState extends ConsumerState<SelectAmcScreen> {
  static const _green = Color(0xFF106220);
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _runSearch() => setState(() => _query = _searchController.text.trim());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final companies = (companiesAsync.valueOrNull ?? const <Company>[])
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? companies
        : companies.where((c) {
            return [c.name, c.branchName, c.location ?? '', c.gstNumber ?? '']
                .any((f) => f.toLowerCase().contains(q));
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: kIsWeb ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Select AMC',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            color: Color(0xFF14201A),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mq = MediaQuery.of(context);
            final width = constraints.maxWidth > 0 ? constraints.maxWidth : mq.size.width;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _runSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search AMC',
                            prefixIcon: const Icon(Icons.search, color: _green),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDCE5DE)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDCE5DE)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _green, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _runSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: companiesAsync.isLoading && companies.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: _green))
                        : filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No results found',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: Color(0xFF6B6B6B),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final c = filtered[index];
                                  return Container(
                                    width: width,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8E3)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                c.displayName,
                                                softWrap: true,
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: Color(0xFF14201A),
                                                ),
                                              ),
                                              if ((c.location ?? '').isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  c.location!,
                                                  softWrap: true,
                                                  style: const TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 12,
                                                    color: Color(0xFF6B6B6B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () => context.pop(c),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Select'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
