import 'package:flutter/material.dart';

class CounterActions extends StatelessWidget {
  const CounterActions({
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    super.key,
  });

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          label: const Text('Tang'),
        ),
        OutlinedButton.icon(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          label: const Text('Giam'),
        ),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}
