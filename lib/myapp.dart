import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'waypoint.dart';
import 'myhomepage.dart';
import 'waypointstorage.dart';
import 'dart:convert';


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



class MyAppState extends ChangeNotifier {

  Position? currentposition;
  StreamSubscription<Position>? positionStream;
  var waypoints = <Waypoint>[];

  final storage = WaypointStorage();


  // Close the position stream before exiting the app.
  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  void restoreWaypoints() async {
    var content = "";

    try {
      content = await storage.readWaypointFile();
      print(content);
    } catch (e) {
      // Do nothing, probably the file does not exist yet
      return;
    }

    var jsonResponse = jsonDecode(content);

    for (var wp in jsonResponse) {
      final waypoint = Waypoint.fromJson(wp);
      waypoints.add(waypoint);
    }

    notifyListeners();

  }

  void saveWaypoints() {
    var json = waypoints.map((waypoint) => waypoint.toJson()).toList();
    storage.writeWaypointFile(jsonEncode(json));
  }

  void updateLocation() async {
    var position = await getCurrentLocation().catchError((e) {
      throw Exception(e.message);
    });
    currentposition = position;
    if (positionStream == null) {
      listenToLocationChanges();
    }
    notifyListeners();
  }

  void listenToLocationChanges() {
    print("listen");
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
        print(position==null? 'Unknown' : 'Position stream: $position');
        currentposition = position;
        notifyListeners();
      },
    );
  }

  void addWaypoint(String name) async {
    String? errormsg;

    // Try to update position
    try {
      currentposition = await getCurrentLocation();
    } on Exception catch (e) {
      errormsg = e.toString().substring(11);
    }

    // Create Waypoint instance
    var waypoint = Waypoint.fromPosition(currentposition!);

    name = name.trim(); // Remove leading and trailing whitespaces
    if (name == '') {
      name = "Unnamed WP (${asLocalTime(currentposition!.timestamp)})";
    }

    waypoint.name = name;

    // Save Waypoint
    waypoints.add(waypoint);
    saveWaypoints();
    notifyListeners();

    // Throw exception if updating location failed
    if (errormsg != null) {
      errormsg = "Saved waypoint with last known position, but could not update position:\n" + errormsg;
      currentposition = null;
      throw Exception(errormsg);
    }
  } // addWaypoint

  void deleteWaypoint(index) {
    waypoints.removeAt(index);
    saveWaypoints();
    notifyListeners();
  }
} // MyAppState

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


String asLocalTime(DateTime datetime) {
  return datetime.toLocal().toString().substring(0,16);
}