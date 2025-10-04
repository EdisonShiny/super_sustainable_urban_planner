import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_service.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.center,
    required this.zoom,
    this.markers = const [],
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: OsmService.tileTemplate,
            additionalOptions: const {},
            subdomains: OsmService.subdomains,
            userAgentPackageName: 'nasa_space_app_testing',
          ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
