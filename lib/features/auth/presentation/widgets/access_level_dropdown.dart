import 'package:flutter/material.dart';
import '../../models/access_level.dart';

class AccessLevelDropdown extends StatelessWidget {
  const AccessLevelDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AccessLevel value;
  final ValueChanged<AccessLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AccessLevel>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Access Level',
        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
        suffixIcon: const Tooltip(
          message:
              'City leaders access planning dashboards; residents share local insights.',
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.info_outline),
          ),
        ),
      ),
      items: AccessLevel.values
          .map(
            (level) => DropdownMenuItem<AccessLevel>(
              value: level,
              child: Text(level.label),
            ),
          )
          .toList(),
      onChanged: (level) {
        if (level != null) {
          onChanged(level);
        }
      },
    );
  }
}
