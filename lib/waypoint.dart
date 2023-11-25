import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  String name = "Unnamed Waypoint";

  double accuracy = 0;
  double altitude = 0;
  double altitudeAccuracy = 0;
  double speed = 0;
  double speedAccuracy = 0;
  double heading = 0;
  double headingAccuracy = 0;

  Waypoint(this.latitude, this.longitude, this.timestamp);

  Waypoint.fromPosition(Position position)
      : latitude = position.latitude,
        longitude = position.longitude,
        timestamp = position.timestamp,
        altitude = position.altitude,
        altitudeAccuracy = position.altitudeAccuracy,
        accuracy = position.accuracy,
        speed = position.speed,
        speedAccuracy = position.speedAccuracy,
        heading = position.heading,
        headingAccuracy = position.headingAccuracy;

  Waypoint.fromJson(Map<String, dynamic> json)
      : latitude = json['geometry']['coordinates'][1],
        longitude = json['geometry']['coordinates'][0],
        timestamp = DateTime.parse(json['properties']['timestamp']),
        name = json['properties']['name'],
        altitude = json['properties']['altitude'],
        accuracy = json['properties']['accuracy'],
        speed = json['properties']['speed'],
        speedAccuracy = json['properties']['speedAccuracy'],
        heading = json['properties']['heading'],
        headingAccuracy = json['properties']['headingAccuracy'];

  Map<String, dynamic> toJson() => {
    // GeoJSON
    'type': 'Feature',
    'properties': {
      'name': name,
      'timestamp': timestamp.toString(),
      'accuracy' : accuracy,
      'altitude': altitude,
      'altitudeAccuracy': altitudeAccuracy,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
      'heading': heading,
      'headingAccuracy': headingAccuracy,
    },
    'geometry': {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    }
  };

  Position toPosition() {
    return Position(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      altitudeAccuracy: altitudeAccuracy,
      timestamp: timestamp,
      speed: speed,
      heading: heading,
      speedAccuracy: speedAccuracy,
      headingAccuracy: headingAccuracy,
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  Marker toMarker(Color? color) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 18,
      height: 18,
      child: Icon(Icons.location_on, size: 18, color: color),
    );
  }

  String get latlon => "Lat, Lon: " + latitude.toString() + ", " + longitude.toString();
}
