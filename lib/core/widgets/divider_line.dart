import 'package:flutter/material.dart';

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: Theme.of(context).dividerColor,
      margin: const EdgeInsets.symmetric(vertical: 24),
    );
  }
}
