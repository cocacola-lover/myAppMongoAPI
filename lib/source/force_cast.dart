class MyCastError implements Exception {
  final String exceptionMessage;
  MyCastError(this.exceptionMessage);

  @override
  String toString() {
    return exceptionMessage;
  }
}

T forceCast<T>(dynamic x) {
  try {
    return (x as T);
  } on TypeError {
    throw MyCastError('CastError when trying to cast $x to $T!');
  }
}
