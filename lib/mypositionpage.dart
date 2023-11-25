import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proj4dart/proj4dart.dart';
import 'myapp.dart';

class MyPositionPage extends StatefulWidget {
  const MyPositionPage({super.key});

  @override
  State<MyPositionPage> createState() => _MyPositionPageState();
}

class _MyPositionPageState extends State<MyPositionPage> {

  // Will be used to get value from text field
  final textController = TextEditingController();

  @override
  void dispose() {
    // Clean up when widget is disposed
    textController.dispose();
    super.dispose();
  }

  void _asyncBtnLoc(appState, scaffoldmessenger) async {
    if (appState.waypoints.length == 0) {
      await appState.restoreWaypoints();
    }
    try {
      await appState.updateLocation();
    } on Exception catch (e) {
      var msg = e.toString().substring(11);
      scaffoldmessenger.showSnackBar(
          SnackBar(
            content: Text(msg),
          )
      );
    }
  }

  void _asyncBtnWP(callback, scaffoldmessenger, name) async {
    try {
      await callback(name);
    } on Exception catch (e) {
      var msg = e.toString().substring(11);
      scaffoldmessenger.showSnackBar(
          SnackBar(
            content: Text(msg),
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var scaffoldmessenger = ScaffoldMessenger.of(context);
    if (appState.currentposition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Current Location is unknown.',
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _asyncBtnLoc(appState, scaffoldmessenger);
              },
              child: const Text('Get Location'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          children: <Widget>[
            ShowStatus(statusOK: (appState.positionStream != null)),
            ShowLocationWGS84(position: appState.currentposition!),
            ShowLocationUTM(position: appState.currentposition!),
            ShowTimestamp(position: appState.currentposition!),
            SizedBox(height:30),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Optional Waypoint Name",
                ),
              ),
            ),
            SizedBox(height:30),
            ElevatedButton(
              onPressed: () {
                _asyncBtnWP(appState.addWaypoint, scaffoldmessenger, textController.text);
                textController.clear();
                // hide keybord
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: const Text('Save Waypoint'),
            ),
          ],
        ),
      );
    }
  }
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
                  Text("Lat: " + position.latitude.toString() + "°"),
                  Text("Lon: " + position.longitude.toString() + "°"),
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


