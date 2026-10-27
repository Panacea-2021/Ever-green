/// The EverGreen backend usually answers HTTP 200 and puts the real outcome in
/// the body as `status` (or `success` on a few routes). Anything other than
/// 200/201 there is a failure, e.g. `{status: 402, message: "Invalid password"}`.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  /// Returns the body code when the payload is an EverGreen envelope with a
  /// non-success code, otherwise null.
  static ApiException? fromEnvelope(dynamic body) {
    if (body is! Map) return null;
    final raw = body['status'] ?? body['success'];
    final code = raw is int ? raw : int.tryParse('$raw');
    if (code == null || code == 200 || code == 201) return null;
    final message = body['message']?.toString().trim();
    return ApiException(
      code,
      (message == null || message.isEmpty) ? 'Request failed ($code)' : message,
    );
  }

  @override
  String toString() => message;
}
