class AppException implements Exception {
  final String exceptionMessage;
  AppException(this.exceptionMessage);

  @override
  String toString() {
    return exceptionMessage;
  }
}
