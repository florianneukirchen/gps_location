import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'myapp.dart';
import 'waypoint.dart';
import 'locationwidgets.dart';
import 'mapwidget.dart';

// Page showing all waypoints
class WaypointsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final current = appState.poslatlng();


    if (appState.waypoints.isEmpty) {
      return Center(
        child: Text('No waypoints yet.'),
      );
    }

    return ListView.builder(
      itemCount: appState.waypoints.length,
      itemBuilder: (BuildContext, int index) {
        final item = appState.waypoints[index];
        return Dismissible(
          key: UniqueKey(),
          // key: Key(item.timestamp.toString()),
          onDismissed: (direction) {
            appState.deleteWaypoint(index);
          },
          background: Container(color: Colors.red),
          child: ListTile(
            leading: Icon(Icons.location_on),
            title: Text(item.name),
            subtitle: Text(asEW_NW(item.latitude, item.longitude) + "\n" +
                asLocalTime(item.timestamp)
                + distanceMessage(current, item.toLatLng())
            ),
            isThreeLine: true,
            onTap: () {
              // Show detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailScreen(waypoint: item, wpindex: index),
                ),
              );
            }
          ),
        );
      },
    );
  }
}

// Create a nice string for the distance
String distanceMessage(LatLng? a, LatLng b) {
  if (a == null) {
    return "";
  } else {
    Distance distance = new Distance();
    return " (➞ ${(distance(a, b) / 1000).toStringAsFixed(2)} km)";
  }
}

// Waypoint detail screen
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.waypoint, required this.wpindex });

  final Waypoint waypoint;
  final int wpindex;

  // handle click on the ... menu in the appbar
  _handleClick(int item) {
    switch (item) {
      case 0:
        {
          Share.share(asEW_NW(waypoint.latitude, waypoint.longitude), subject: waypoint.name);
        }
        break;
      case 1:
        {
          var json = waypoint.toJson();
          Share.share(jsonEncode(json), subject: waypoint.name);
        }
        break;
      case 2:
        {
          final utmzone = getUTMzone(waypoint.toPosition());
          final (pointutm, epsg) = reprojectUTM(waypoint.toPosition(), utmzone);
          Share.share(
              utmzone.toString()
                  + " N "
                  + pointutm.x.toStringAsFixed(0)
                  + " " + pointutm.y.toStringAsFixed(0)
                  + " ("+ epsg + ")",
              subject: waypoint.name);
        }
      default:
        throw UnimplementedError("Not implemented");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waypoint Details'),
        actions: <Widget>[
          // menu button "..."
          PopupMenuButton<int>(
            onSelected: (item) => _handleClick(item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(value: 0, child: Text('Share as Lat Lon')),
              PopupMenuItem<int>(value: 1, child: Text('Share as JSON')),
              PopupMenuItem<int>(value: 2, child: Text('Share as UTM')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          BigCard(text: waypoint.name),
          ShowLocation(position: waypoint.toPosition()),
          ShowDistance(latlng: waypoint.toLatLng(),),
          MyMap(activeindex: wpindex,),
        ],
      ),
      );
  }

}

// used for waypoint name
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Row(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(text,
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }
}