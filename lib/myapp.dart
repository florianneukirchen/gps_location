import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'waypoint.dart';
import 'myhomepage.dart';
import 'waypointstorage.dart';
import 'dart:convert';

enum SortOrder { timeAscending, timeDescending, nameAscending, nameDescending, distanceAscending, distanceDescending }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Manage State with provider
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
  // Constructor to init appstate with waypoints and position
  MyAppState(){
    restoreSettings();
    restoreWaypoints();
    try {
      updateLocation();
    } catch (e) {
      // Do nothing if position is not known
      // the user will get the "Current Position Unknown" page
    }
  }

  // Declare Variables
  Position? currentposition;
  StreamSubscription<Position>? positionStream;
  var waypoints = <Waypoint>[];

  final storage = WaypointStorage();

  SortOrder sortOrder = SortOrder.timeAscending;

  // Close the position stream before exiting the app.
  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // Restore / Save Waypoints
  void restoreWaypoints() async {
    var content = "";

    try {
      content = await storage.readWaypointFile();
    } catch (e) {
      // Do nothing, probably the file does not exist yet
      return;
    }

    var jsonResponse = jsonDecode(content);

    for (var wp in jsonResponse['features']) {
      final waypoint = Waypoint.fromJson(wp);
      waypoints.add(waypoint);
    }
    notifyListeners();
  }

  void saveWaypoints() {
    var json = waypoints.map((waypoint) => waypoint.toJson()).toList();
    final featurecollection = {
      "type": "FeatureCollection",
      "features": json,
    };
    storage.writeWaypointFile(jsonEncode(featurecollection));
  }

  // Restore / Save Settings
  void restoreSettings() async {
    var content = "";

    try {
      content = await storage.readSettingsFile();
    } catch (e) {
      // Do nothing, probably the file does not exist yet
      return;
    }

    var jsonResponse = jsonDecode(content);
    sortOrder = SortOrder.values.byName(jsonResponse['sort order']);
    // May use more settings at a later stage
  }

  void saveSettings() {
    final json = <String, dynamic>{};
    json['sort order'] = sortOrder.name;
    storage.writeSettingsFile(jsonEncode(json));
  }

  Future<void> updateLocation() async {
    var position = await getCurrentLocation().catchError((e) {
      // Throw exception again, to be catched in calling functions
      throw Exception(e.message);
    });
    currentposition = position;
    // Subscribe to Location Stream if not yet listening
    if (positionStream == null) {
      listenToLocationChanges();
    }
    notifyListeners();
  }

  // Subscribe to location stream
  void listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // in meters, location gets updated if change > filter
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
        currentposition = position;
        notifyListeners();
      },
    );
  }

  void sortWaypoints() {
    switch (sortOrder) {
      case SortOrder.timeDescending:
        // Sort by timestamp, old to recent
        waypoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOrder.timeAscending:
        // Sort by timestamp, recent to old
        waypoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOrder.nameAscending:
        // Sort by name A-Z
        waypoints.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOrder.nameDescending:
      // Sort by name Z-A
        waypoints.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOrder.distanceAscending:
        // Sort by Distance, from close to far
        // Fall-back if current position not known
        if (currentposition == null) {
          waypoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          break;
        }
        waypoints.sort(sortCompareByDistance);
        break;
      case SortOrder.distanceDescending:
      // Fall-back if current position not known
        if (currentposition == null) {
          waypoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          break;
        }
        waypoints.sort((sortCompareByDistance));
        waypoints = waypoints.reversed.toList();
        break;
      default:
        throw UnimplementedError("Sort method not implemented");
    }
  }

  // Compare function for sorting
  int sortCompareByDistance(Waypoint a, Waypoint b) {
    Distance distance = Distance();
    final dist_a = distance(poslatlng()!, a.toLatLng());
    final dist_b = distance(poslatlng()!, b.toLatLng());

    if (dist_a < dist_b) {
      return -1;
    } else if (dist_a > dist_b) {
      return 1;
    } else {
      return 0;
    }
  }

  Future<void> addWaypoint(String name) async {
    String? errormsg;

    // Try to update position
    try {
      currentposition = await getCurrentLocation();
    } on Exception catch (e) {
      // Cut off "Exception..." from string
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
    sortWaypoints();
    saveWaypoints();
    notifyListeners();

    // Throw exception if updating location failed
    if (errormsg != null) {
      errormsg = "Saved waypoint with last known position, but could not update position:\n" + errormsg;
      // And set currentposition to null, redirects to "Position Unknown" page
      currentposition = null;
      throw Exception(errormsg);
    }
  } // addWaypoint

  void deleteWaypoint(index) {
    waypoints.removeAt(index);
    saveWaypoints();
    notifyListeners();
  }

  void deleteAllWaypoints() {
    waypoints.clear();
    saveWaypoints();
    notifyListeners();
  }

  // Get current position as LatLng
  LatLng? poslatlng() {
    if (currentposition == null) {
      return null;
    }
    return LatLng(currentposition!.latitude, currentposition!.longitude);
  }
} // MyAppState

// Get current location from Geolocator
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

// Convert UTC timestamp to local time
String asLocalTime(DateTime datetime) {
  return datetime.toLocal().toString().substring(0,16);
}

