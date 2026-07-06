class StringStream {
  static String makeNull(String? str, String defaultValue) {
    String nonNullableString = str?.isEmpty == false ? str! : defaultValue;
    return nonNullableString;
  }
}

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple(this.item1, this.item2);

  @override
  String toString() => '($item1, $item2)';
}