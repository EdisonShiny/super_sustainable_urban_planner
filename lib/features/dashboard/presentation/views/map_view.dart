import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/emoji_status_badge.dart';
import '../../../maps/widgets/map_canvas.dart';
import '../../models/city_region.dart';

class MapView extends StatelessWidget {
  const MapView({super.key, required this.city, required this.mood});

  final CityRegion city;
  final CityStatusMood mood;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(city.latitude ?? 0, city.longitude ?? 0);
    final hasCoordinates = city.latitude != null && city.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(label: Text('${city.displayName} - ${mood.emoji}')),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: hasCoordinates
              ? MapCanvas(
                  key: ValueKey(
                    'map-${city.id}-${city.latitude}-${city.longitude}',
                  ),
                  center: center,
                  zoom: 11,
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                  ],
                )
              : _buildPlaceholder(context),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(
        child: Icon(Icons.public_off, size: 48, color: Colors.grey),
      ),
    );
  }
}
