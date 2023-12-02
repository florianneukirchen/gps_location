import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'myapp.dart';

class MyMap extends StatelessWidget {
  const MyMap({
    super.key,
    this.activeindex,
    this.linkmarkers = false,
  });

  final int? activeindex;
  final bool linkmarkers;

  @override
  Widget build(BuildContext context) {

    var appState = context.watch<MyAppState>();
    LatLng initialCenter = LatLng(0,0);

    if (activeindex != null) {
      initialCenter = appState.waypoints[activeindex!].toLatLng();
    } else if (appState.currentposition != null) {
      initialCenter = appState.poslatlng()!;
    } else if (appState.waypoints.isNotEmpty) {
      // Use the last waypoint of the list. If not keep LatLng 0,0
      initialCenter = appState.waypoints.last.toLatLng();

    }

    return Expanded(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          SimpleAttributionWidget(
            source: Text('OpenStreetMap'),
            backgroundColor: Colors.transparent,
          ),
          if (appState.currentposition != null) MarkerLayer(
            markers: [
              Marker(
                point: appState.poslatlng()!,
                width: 18,
                height: 18,
                child: Icon(
                    Icons.my_location,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary
                ),
              ),
            ],
            alignment: Alignment.center,
          ),
          wpMarkerLayer(activeindex: activeindex, linkmarkers: linkmarkers),
        ],
      ),
    );
  }
}




class wpMarkerLayer extends StatelessWidget {
  const wpMarkerLayer({super.key, this.activeindex, required this.linkmarkers});

  final int? activeindex;
  final bool linkmarkers;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final waypoints = appState.waypoints;
    var markers = <Marker>[];

    final activeColor = Theme
        .of(context)
        .colorScheme
        .primary;

    if (linkmarkers) {
      for (var i = 0; i < waypoints.length; i++) {
        final wp = waypoints[i];
        markers.add(wp.toLinkMarker(i));
      }
    } else {
      for (var i = 0; i < waypoints.length; i++) {
        final wp = waypoints[i];
        if (i != activeindex) {
          markers.add(wp.toMarker(null));
        }
        if (activeindex != null) {
          markers.add(waypoints[activeindex!].toMarker(activeColor));
        }

      }
    }


    return MarkerLayer(
      markers: markers,
      // Keine Ahnung warum, aber das Ergebnis ist bottomCenter
      alignment: Alignment.center,
    );
  }
}


