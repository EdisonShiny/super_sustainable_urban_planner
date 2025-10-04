import 'dart:async';
import 'package:flutter/material.dart';

class CitySearchBar extends StatefulWidget {
  const CitySearchBar({
    super.key,
    required this.onQueryChanged,
    this.onSubmitted,
    this.initialValue,
  });

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String>? onSubmitted;
  final String? initialValue;

  @override
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant CitySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onQueryChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
