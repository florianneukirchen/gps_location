import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proj4dart/proj4dart.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'myapp.dart';

// Can be used for current position as well as for waypoint details
class ShowLocation extends StatelessWidget {
  const ShowLocation({
    super.key,
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          ShowLocationWGS84(position: position),
          ShowLocationUTM(position: position),
          ShowTimestamp(position: position),
        ]
      ),
    );
  }
}

String asEW_NW(double lat, double lon){
  String slat;
  String slon;
  if (lat >= 0) {
    slat = lat.toString() + "° N ";
  } else {
    slat = lat.abs().toString() + "° S ";
  }
  if (lon >= 0) {
    slon = lon.toString() + "° E";
  } else {
    slon = lon.abs().toString() + "° W";
  }
  return slat + slon;
}

class ShowLocationWGS84 extends StatelessWidget {
  const ShowLocationWGS84({
    super.key,
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Lat, Lon: " + asEW_NW(position.latitude, position.longitude)),
                  Text("(± " + position.accuracy.toStringAsFixed(1) + " m)"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Speed: ${position.speed.toStringAsFixed(1)} m/s (± ${position.speedAccuracy.toStringAsFixed(1)})"
                  ),
                  Text("Heading: ${position.heading.toStringAsFixed(0)}° (± ${position.headingAccuracy}°)"
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Altitude (WGS84): " + position.altitude.toString() + " m"),
                  Text("± " + position.altitudeAccuracy.toString() + " m"),
                ],
              ),
            ],
          ),
        ));
  }
}


class ShowTimestamp extends StatelessWidget {
  const ShowTimestamp({
    super.key,
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text("Timestamp: " + position.timestamp.toString()),
                ],
              ),
              Row(
                children: [
                  Text("Local time: " + asLocalTime(position.timestamp)),
                ],
              )
            ],
          ),
        ));
  }
}

class ShowDistance extends StatelessWidget {
  const ShowDistance({
    super.key,
    required this.latlng,
  });

  final LatLng latlng;


  @override
  Widget build(BuildContext context) {
    final current = Provider.of<MyAppState>(context).poslatlng();
    Distance distance = new Distance();
    String msg;

    if (current == null) {
      msg = "Current position not known";
    } else {
      msg = "Distance: ${(distance(current, latlng) / 1000).toStringAsFixed(1)} km";
    }

    return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                      msg
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}


class ShowStatus extends StatelessWidget {
  const ShowStatus({
    super.key,
    required this.statusOK,
  });

  final bool statusOK;

  @override
  Widget build(BuildContext context) {
    var msg = "Listening to GSP stream";
    if (!statusOK) {
      msg = "Not updating position";
    }
    return Text(msg);
  }
}

class ShowLocationUTM extends StatelessWidget {
  const ShowLocationUTM({
    super.key,
    required this.position,
  });

  final Position position;

  int getUTMzone(Position position) {
    int utmzone = ((position.longitude + 180) / 6).floor() + 1;

    // Southern Norway
    if (position.latitude >= 72.0 && position.latitude < 64.0 && position.longitude >= 3.0 && position.latitude < 12.0) {
      utmzone = 32;
    }

    // Svalbart
    if (position.latitude >= 72.0 && position.longitude < 84.0 ) {
      if (position.longitude >= 0.0 && position.longitude < 9.0) {
        utmzone = 31;
      } else if (position.longitude >= 9.0 && position.longitude < 21.0) {
        utmzone = 33;
      } else if (position.longitude >= 21.0 && position.longitude < 33.0) {
        utmzone = 35;
      } else if (position.longitude >= 33.0 && position.longitude < 42.0){
        utmzone = 37;
      }
    }

    return utmzone;
  }

  (Point, String) reprojectUTM(Position position, int utmzone, {bool etrs89 = false}) {
    var pointSrc = Point(x: position.latitude, y: position.longitude);

    // WGS84
    var epsg = 'EPSG:326$utmzone';
    String projstring = "+proj=utm +zone=$utmzone +datum=WGS84 +units=m +no_defs +type=crs";

    if (etrs89) {
      epsg = 'EPSG:258$utmzone';
      projstring = "+proj=utm +zone=$utmzone +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs";
    }

    // Set up proj (proj4dart only has few named projections)
    // Get it by name if it exists, else create and add it
    var projDst = Projection.get(epsg) ?? Projection.add(epsg, projstring);
    var projSrc = Projection.get('EPSG:4326')!;
    var pointDst = projSrc.transform(projDst, pointSrc);

    return (pointDst, epsg);
  }

  @override
  Widget build(BuildContext context) {
    final utmzone = getUTMzone(position);
    final (pointutm, epsg) = reprojectUTM(position, utmzone);
    // final (pointetrs89, epsg89) = reprojectUTM(position, utmzone, etrs89: true);
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text("UTM Zone $utmzone N ($epsg)"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("X: " + pointutm.x.toStringAsFixed(1) + " m"),
                  Text("Y: " + pointutm.y.toStringAsFixed(1) + " m"),
                  Text("(± " + position.accuracy.toStringAsFixed(1) + " m)"),
                ],
              ),
              /*
              SizedBox(height: 8),
              Text("UTM Zone $utmzone N (ETRS89, $epsg89)"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("X: " + pointetrs89.x.toStringAsFixed(1) + " m"),
                  Text("Y: " + pointetrs89.y.toStringAsFixed(1) + " m"),
                  Text("(± " + position.accuracy.toStringAsFixed(1) + " m)"),
                ],
              ),

               */

            ],
          ),
        ));
  }
}

