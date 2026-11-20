abstract class Failure {
  String get message;
  String get displayMessage => message;

  // Factory constructors for convenient creation
  const factory Failure.network({required String message}) = NetworkFailure;
  const factory Failure.noConnection() = NoConnectionFailure;
  const factory Failure.timeout() = TimeoutFailure;
  factory Failure.server({
    required String message,
    required int statusCode,
    Map<String, dynamic>? errors,
  }) = ServerFailure;
  factory Failure.authentication({required String message}) =
      AuthenticationFailure;
  factory Failure.validation({
    required String message,
    required Map<String, List<String>> fieldErrors,
  }) = ValidationFailure;
  factory Failure.parsing({required String message, String? rawData}) =
      ParsingFailure;
  factory Failure.cache({required String message}) = CacheFailure;
  factory Failure.unknown({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnknownFailure;
}

class NetworkFailure implements Failure {
  @override
  final String message;
  final int? statusCode;

  const NetworkFailure({required this.message, this.statusCode});

  @override
  String get displayMessage => message;
}

class ServerFailure implements Failure {
  @override
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ServerFailure({required this.message, required this.statusCode, this.errors});

  @override
  String get displayMessage => message;
}

class AuthenticationFailure implements Failure {
  @override
  final String message;

  const AuthenticationFailure({required this.message});

  @override
  String get displayMessage => message;
}

class ValidationFailure implements Failure {
  @override
  final String message;
  final Map<String, List<String>> fieldErrors;

  ValidationFailure({required this.message, required this.fieldErrors});

  @override
  String get displayMessage => message;
}

class ParsingFailure implements Failure {
  @override
  final String message;
  final String? rawData;

  ParsingFailure({required this.message, this.rawData});

  @override
  String get displayMessage => 'Data processing error';
}

class CacheFailure implements Failure {
  @override
  final String message;

  CacheFailure({required this.message});

  @override
  String get displayMessage => message;
}

class NoConnectionFailure implements Failure {
  @override
  final String message;

  const NoConnectionFailure({this.message = 'No internet connection'});

  @override
  String get displayMessage => message;
}

class TimeoutFailure implements Failure {
  @override
  final String message;

  const TimeoutFailure({this.message = 'Request timed out'});

  @override
  String get displayMessage => message;
}

class UnknownFailure implements Failure {
  @override
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  UnknownFailure({required this.message, this.error, this.stackTrace});

  @override
  String get displayMessage => 'An unexpected error occurred';
}
