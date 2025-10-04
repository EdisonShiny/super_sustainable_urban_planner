import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/strings.dart';

class TopControls extends StatelessWidget {
  const TopControls({
    super.key,
    required this.showMap,
    required this.onToggle,
    required this.lastUpdated,
  });

  final bool showMap;
  final ValueChanged<bool> onToggle;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy - h:mm a');
    final lastUpdatedText = lastUpdated == null
        ? 'No data yet'
        : '${AppStrings.lastUpdated}: ${formatter.format(lastUpdated!)}';

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ToggleButtons(
            isSelected: [showMap, !showMap],
            onPressed: (index) => onToggle(index == 0),
            renderBorder: false,
            borderRadius: BorderRadius.circular(16),
            fillColor: Theme.of(context).colorScheme.primary,
            selectedColor: Colors.white,
            color: Theme.of(context).colorScheme.onSurface,
            constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Map View'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Graph View'),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Text(
              lastUpdatedText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
