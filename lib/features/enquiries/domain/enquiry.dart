/// Customer repair enquiry submitted through the "Book a Repair" popup.
///
/// Backend integration is pending: the fields below mirror the expected
/// contract documented at the bottom of this file. Until the backend ships
/// the endpoint, the repository returns an integration-pending error and the
/// screen shows an empty state.
class Enquiry {
  const Enquiry({
    required this.tokenId,
    required this.customerName,
    required this.phone,
    this.email,
    this.equipment,
    this.service,
    this.requestType,
    this.problemDescription,
    this.photos = const [],
    this.submissionDate,
    this.status = EnquiryStatus.pending,
  });

  final String tokenId;
  final String customerName;
  final String phone;
  final String? email;
  final String? equipment;
  final String? service;
  final String? requestType;
  final String? problemDescription;
  final List<String> photos;
  final DateTime? submissionDate;
  final EnquiryStatus status;

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse('$v')?.toLocal();
    final photosRaw = json['photos'] ?? json['images'] ?? json['uploaded_photos'];
    final photos = photosRaw is List ? photosRaw.map((e) => '$e').toList() : const <String>[];
    return Enquiry(
      tokenId: '${json['token_id'] ?? json['tokenId'] ?? json['id'] ?? ''}',
      customerName: '${json['customer_name'] ?? json['customerName'] ?? json['name'] ?? ''}',
      phone: '${json['phone'] ?? json['phone_number'] ?? ''}',
      email: (json['email'] as String?)?.trim().isEmpty == true ? null : json['email']?.toString(),
      equipment: (json['equipment'] ?? json['equipment_name'])?.toString(),
      service: (json['service'] ?? json['service_name'])?.toString(),
      requestType: (json['request_type'] ?? json['requestType'] ?? json['type'] ?? json['booking_type'])?.toString(),
      problemDescription: (json['problem_description'] ?? json['problemDescription'] ?? json['description'])?.toString(),
      photos: photos,
      submissionDate: parseDate(json['submission_date'] ?? json['submissionDate'] ?? json['created_at']),
      status: EnquiryStatus.fromKey(json['status']),
    );
  }
}

enum EnquiryStatus {
  pending('pending', 'Pending'),
  underReview('under_review', 'Under Review'),
  confirmed('confirmed', 'Confirmed'),
  rejected('rejected', 'Rejected'),
  completed('completed', 'Completed'),
  contacted('Contacted', 'Contacted'),
  cancelled('cancelled', 'Cancelled');

  const EnquiryStatus(this.key, this.label);
  final String key;
  final String label;

  static EnquiryStatus fromKey(dynamic key) {
    final s = '$key'.trim().toLowerCase().replaceAll(' ', '_');
    switch (s) {
      case 'pending':
      case 'new':
        return EnquiryStatus.pending;
      case 'under_review':
      case 'in_progress':
      case 'inprogress':
        return EnquiryStatus.underReview;
      case 'confirmed':
        return EnquiryStatus.confirmed;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return s == 'cancelled' || s == 'canceled' ? EnquiryStatus.cancelled : EnquiryStatus.rejected;
      case 'completed':
      case 'done':
        return EnquiryStatus.completed;
      case 'contacted':
        return EnquiryStatus.contacted;
      default:
        return EnquiryStatus.pending;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Backend API contract required (to be implemented by the backend team):
///
/// GET  /enquiries            (or /user/getAllEnquiries)
///   Query params (all optional):
///     - search: string (matches customer name, phone, email)
///     - status: 'new' | 'in_progress' | 'completed' | 'cancelled'
///     - page: int (1-based)
///     - pageSize: int
///   Auth: Bearer JWT (Super Admin / authorised Manager)
///   Response: { success, data: [Enquiry], total: int, page, pageSize }
///     Enquiry fields: token_id, customer_name, phone, email, equipment,
///     service, submission_date (ISO), status
///
/// GET  /enquiries/:tokenId   (or /user/getEnquiry/:tokenId)
///   Auth: Bearer JWT
///   Response: { success, data: Enquiry }
///
/// PATCH /enquiries/:tokenId/status   (or /user/updateEnquiryStatus/:tokenId)
///   Body: { status: 'new'|'in_progress'|'completed'|'cancelled' }
///   Auth: Bearer JWT
///   Response: { success, data: Enquiry }
/// ---------------------------------------------------------------------------
