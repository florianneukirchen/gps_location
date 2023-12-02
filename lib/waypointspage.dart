import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'myapp.dart';
import 'waypoint.dart';
import 'locationwidgets.dart';
import 'mapwidget.dart';

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

String distanceMessage(LatLng? a, LatLng b) {
  if (a == null) {
    return "";
  } else {
    Distance distance = new Distance();
    return " (➞ ${(distance(a, b) / 1000).toStringAsFixed(2)} km)";
  }


}


class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.waypoint, required this.wpindex });

  final Waypoint waypoint;
  final int wpindex;

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
          PopupMenuButton<int>(
            onSelected: (item) => _handleClick(item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(value: 0, child: Text('Share as Lat Lon')),
              PopupMenuItem<int>(value: 1, child: Text('Share as JSON')),
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
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(text,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}