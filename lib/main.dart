import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proj4dart/proj4dart.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MyAppState(),
        child: MaterialApp(
          title: 'GPS Location',
          theme: ThemeData(
            // This is the theme of your application.
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'GPS Location'),
        ),
    );
  }
}

class Waypoint {
  final Position position;
  String name = "Unnamed Waypoint";

  Waypoint(this.position);

  DateTime get timestamp => position.timestamp;
  double get longitude => position.longitude;
  double get latitude => position.latitude;
  String get latlon => "Lat, Lon: " + position.latitude.toString() + ", " + position.longitude.toString();
}


class MyAppState extends ChangeNotifier {

  Position? currentposition;
  StreamSubscription<Position>? positionStream;
  var waypoints = <Waypoint>[];

  // Close the position stream before exiting the app.
  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  void updateLocation() async {
    currentposition = await getCurrentLocation();
    notifyListeners();
  }

  void listenToLocationChanges() {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
        print(position==null? 'Unknown' : 'Stream $position');
        currentposition = position;
        notifyListeners();
      },
    );
  }

  void addWaypoint(String name) {
    name = name.trim(); // Remove leading and trailing whitespaces
    if (name == '') {
      name = "Unnamed Waypoint";
    }


    var waypoint = Waypoint(currentposition!);
    waypoint.name = name;
    waypoints.add(waypoint);
    notifyListeners();
  }
}

// Get current location
Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    throw Exception('Location Services are disabled');
  }

  permission = await Geolocator.checkPermission();
  if(permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if(permission == LocationPermission.denied) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      throw Exception('Location Permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Everything is fine, continue accessing the position of the device.
  Position position = await Geolocator.getCurrentPosition();
  print("Current Position: $position" );
  return position;
} // _getCurrentLocation




class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MyPositionPage();
        break;
      case 1:
        page = WaypointsPage();
      default:
        throw UnimplementedError("No widget for selected index");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations:[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Current Position",
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_location_alt_outlined),
            label: "Waypoints"
          )
        ],
      ),
      body: page,
      );
  }
}

class MyPositionPage extends StatefulWidget {
  const MyPositionPage({super.key});

  @override
  State<MyPositionPage> createState() => _MyPositionPageState();
}

class _MyPositionPageState extends State<MyPositionPage> {



  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
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
              onPressed: appState.updateLocation,
              child: const Text('Get Location'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          children: <Widget>[
            ShowLocationWGS84(position: appState.currentposition!),
            ShowLocationUTM(position: appState.currentposition!),
            SizedBox(height:30),
            ElevatedButton(
              onPressed: () {
                appState.addWaypoint("name");
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
                  Text("Speed: "
                      + position.speed.toString()
                      + " m/s (± "
                      + position.speedAccuracy.toString() + ")"
                  ),
                  Text("Heading: "
                      + position.heading.toString()
                      + "° (± "
                      + position.headingAccuracy.toString() + "°)"
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
              Text("Timestamp: " + position.timestamp.toString()),
            ],
          ),
        ));
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
    var projDst = Projection.add(epsg, projstring);
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


class WaypointsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.waypoints.isEmpty) {
      return Center(
        child: Text('No waypoints yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${appState.waypoints.length} Waypoints'),
        ),
        for (var wp in appState.waypoints)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(wp.name),
            subtitle: Text(wp.latlon + "\n" + wp.timestamp.toString()),
            isThreeLine: true,
          ),
      ],
    );
  }
}