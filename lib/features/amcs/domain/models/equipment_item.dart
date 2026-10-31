import '../../../../core/models/backend_models.dart';

/// Operational status of a piece of equipment (`equipment.status`).
enum EquipmentStatus { operational, underMaintenance, faulty, retired }

extension EquipmentStatusX on EquipmentStatus {
  String get label {
    switch (this) {
      case EquipmentStatus.operational:
        return 'Operational';
      case EquipmentStatus.underMaintenance:
        return 'Under Maintenance';
      case EquipmentStatus.faulty:
        return 'Faulty';
      case EquipmentStatus.retired:
        return 'Retired';
    }
  }

  String get key => name;

  /// The backend `equipment_status` value.
  EquipmentCondition get condition {
    switch (this) {
      case EquipmentStatus.operational:
        return EquipmentCondition.operational;
      case EquipmentStatus.underMaintenance:
        return EquipmentCondition.underMaintenance;
      case EquipmentStatus.faulty:
        return EquipmentCondition.faulty;
      case EquipmentStatus.retired:
        return EquipmentCondition.retired;
    }
  }

  static EquipmentStatus fromCondition(EquipmentCondition c) {
    switch (c) {
      case EquipmentCondition.operational:
        return EquipmentStatus.operational;
      case EquipmentCondition.underMaintenance:
        return EquipmentStatus.underMaintenance;
      case EquipmentCondition.faulty:
        return EquipmentStatus.faulty;
      case EquipmentCondition.retired:
        return EquipmentStatus.retired;
    }
  }

  static EquipmentStatus fromKey(String? key) {
    for (final s in EquipmentStatus.values) {
      if (s.name == key || s.condition.key == key) return s;
    }
    return EquipmentStatus.operational;
  }
}

/// A single piece of equipment under an AMC/company.
class EquipmentItem {
  final String id;
  final String name;
  final String type;
  final String companyName;
  final String serialNumber;
  final EquipmentStatus status;
  final DateTime installedAt;
  final String? imageUrl;

  /// The backend row this item was built from, when available.
  final Equipment? source;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.companyName,
    required this.serialNumber,
    this.status = EquipmentStatus.operational,
    required this.installedAt,
    this.imageUrl,
    this.source,
  });

  factory EquipmentItem.fromEquipment(Equipment e) {
    final makeModel = [e.make, e.model].whereType<String>().join(' ').trim();
    final created =
        DateTime.tryParse('${e.raw['created_at'] ?? ''}')?.toLocal();
    return EquipmentItem(
      id: '${e.id}',
      name: e.name,
      type: e.type ?? makeModel,
      companyName: e.company?.displayName ?? '',
      serialNumber: e.egSerialNumber.isNotEmpty
          ? e.egSerialNumber
          : (e.serialNumber ?? ''),
      status: EquipmentStatusX.fromCondition(e.status),
      installedAt:
          e.installedAt ?? e.manufacturerDate ?? created ?? DateTime.now(),
      imageUrl: e.imageUrl,
      source: e,
    );
  }

  EquipmentItem copyWith({
    String? name,
    String? type,
    String? companyName,
    String? serialNumber,
    EquipmentStatus? status,
    DateTime? installedAt,
    String? imageUrl,
  }) {
    return EquipmentItem(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      companyName: companyName ?? this.companyName,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      installedAt: installedAt ?? this.installedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'companyName': companyName,
        'serialNumber': serialNumber,
        'status': status.key,
        'installedAt': installedAt.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      status: EquipmentStatusX.fromKey(json['status'] as String?),
      installedAt:
          DateTime.tryParse('${json['installedAt']}') ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
