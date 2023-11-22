import 'package:geolocator/geolocator.dart';

class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  String name = "Unnamed Waypoint";

  double altitude = 0;
  double accuracy = 0;
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
        accuracy = position.accuracy,
        speed = position.speed,
        speedAccuracy = position.speedAccuracy,
        heading = position.heading,
        headingAccuracy = position.headingAccuracy;

  String get latlon => "Lat, Lon: " + latitude.toString() + ", " + longitude.toString();
}
