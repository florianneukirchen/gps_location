import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'myapp.dart';

class MyMap extends StatelessWidget {
  const MyMap({super.key});

  @override
  Widget build(BuildContext context) {

    var appState = context.watch<MyAppState>();

    return Expanded(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: appState.poslatlng(),
          initialZoom: 12,
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
          MarkerLayer(
            markers: [
              Marker(
                point: appState.poslatlng(),
                width: 18,
                height: 18,
                child: Icon(Icons.my_location, size: 18),
              ),
            ],
          )
        ],
      ),
    );
  }
}

