import 'package:flutter/material.dart';

class DepartmentAgenciesField extends StatelessWidget {
  const DepartmentAgenciesField({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: const InputDecoration(
        labelText: 'Department / Agencies',
        prefixIcon: Icon(Icons.apartment_outlined),
      ),
    );
  }
}
