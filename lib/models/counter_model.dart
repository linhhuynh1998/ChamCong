class CounterModel {
  const CounterModel({required this.value});

  final int value;

  CounterModel copyWith({int? value}) {
    return CounterModel(
      value: value ?? this.value,
    );
  }
}
