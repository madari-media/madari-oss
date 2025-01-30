extension FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

extension LastWhereOrNullExtension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    T? elementItem;

    for (var element in this) {
      if (test(element)) {
        elementItem = element;
      }
    }
    return elementItem;
  }
}
