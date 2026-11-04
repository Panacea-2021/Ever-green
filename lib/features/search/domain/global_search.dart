import '../../../core/auth/permissions.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/router/routes.dart';
import '../../auth/domain/models/user_model.dart';

/// The result groups shown as tabs on the global search screen.
enum SearchTab {
  companies('Companies'),
  equipments('Equipments'),
  tasks('Tasks'),
  serviceEngineers('Service Engineers');

  const SearchTab(this.label);
  final String label;
}

/// Tabs [role] may see: each tab's results open a screen the role is allowed
/// to reach, and its data comes from an endpoint the backend serves to it.
List<SearchTab> searchTabsFor(UserRole role) => [
      if (Permissions.canAccessRoute(role, Routes.amcs)) SearchTab.companies,
      SearchTab.equipments,
      SearchTab.tasks,
      // `getAllUser` lists service engineers only for admins and senior
      // service engineers.
      if (Permissions.canAccessRoute(role, Routes.technicianTasks) &&
          role != UserRole.technician)
        SearchTab.serviceEngineers,
    ];

/// Whether every whitespace-separated word of [query] appears
/// (case-insensitively) in at least one of [fields]. A blank query matches
/// everything.
bool matchesQuery(String query, Iterable<String?> fields) {
  final words =
      query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = fields
      .where((f) => f != null && f.isNotEmpty)
      .map((f) => f!.toLowerCase())
      .join('\n');
  return words.every(haystack.contains);
}

/// The items of [items] whose [fields] match [query], in their original order.
List<T> filterByQuery<T>(
  Iterable<T> items,
  String query,
  Iterable<String?> Function(T item) fields,
) =>
    [
      for (final item in items)
        if (matchesQuery(query, fields(item))) item,
    ];

Iterable<String?> companySearchFields(
  Company c, {
  bool includeWebFields = false,
}) =>
    [
      c.name,
      c.branchName,
      c.location,
      c.gstNumber,
      c.serviceType?.label,
      c.amcType?.label,
      c.poc?.name,
      c.poc?.phone,
      c.pocEmail,
      if (includeWebFields) ...[
        c.displayName,
        c.email,
        c.serviceType?.key,
        c.isActive ? 'Active' : 'Inactive',
      ],
    ];

/// [companyName] covers equipment rows that arrive without a nested company.
Iterable<String?> equipmentSearchFields(
  Equipment e, {
  String? companyName,
  bool includeWebFields = false,
}) =>
    [
      e.name,
      e.make,
      e.model,
      e.serialNumber,
      e.egSerialNumber,
      e.location,
      e.company?.name,
      e.company?.branchName,
      companyName,
      if (includeWebFields) ...[
        e.description,
        e.specifications,
        e.type,
        e.status.label,
        e.serviceType?.name,
        e.company?.poc?.name,
        e.company?.poc?.phone,
        e.company?.pocEmail,
      ],
    ];

Iterable<String?> taskSearchFields(
  ServiceTask t, {
  bool includeWebFields = false,
}) {
  final contact = taskContact(t);
  return [
    t.ticketNo,
    t.name,
    t.description,
    t.company?.name,
    t.company?.branchName,
    t.equipment?.name,
    t.equipment?.egSerialNumber,
    t.equipment?.serialNumber,
    t.status.label,
    t.technician?.name,
    t.client?.name,
    t.manager?.name,
    contact.name,
    contact.phone,
    contact.address,
    if (includeWebFields) ...[
      t.equipment?.serviceType?.name,
      t.equipment?.status.label,
      t.equipment?.company?.poc?.name,
      t.equipment?.company?.poc?.phone,
      t.equipment?.company?.pocEmail,
      t.priority.label,
      t.approval.label,
      t.callType?.label,
      t.issueTypeLabel,
      t.technician?.phone,
      t.manager?.phone,
      t.client?.phone,
      t.company?.serviceLabel,
    ],
  ];
}

Iterable<String?> engineerSearchFields(
  User u, {
  bool includeWebFields = false,
}) =>
    [
      u.name,
      u.phone,
      u.email,
      engineerDesignation(u),
      if (includeWebFields) ...[
        u.role.label,
        u.isActive ? 'Active' : 'Inactive',
      ],
    ];

/// Display designation; older rows may still store "Junior Technician".
String engineerDesignation(User u) {
  if (u.role.isTechnicianLevel) return u.role.label;
  final d = u.designation?.trim() ?? '';
  return d.isEmpty ? u.role.label : d;
}

/// Contact details stored on individual (non-company) tickets. They live on
/// the `tasks` row, which `getAllTasks` nests under `task`.
({String? name, String? phone, String? address}) taskContact(ServiceTask t) {
  final nested = t.raw['task'];
  final row = nested is Map ? nested : t.raw;
  String? read(String key) {
    final v = row[key]?.toString().trim();
    return v == null || v.isEmpty ? null : v;
  }

  return (
    name: read('contact_name'),
    phone: read('contact_phone'),
    address: read('address'),
  );
}
