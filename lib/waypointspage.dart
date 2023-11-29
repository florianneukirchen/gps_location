import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'myapp.dart';
import 'waypoint.dart';
import 'locationwidgets.dart';
import 'mapwidget.dart';

class WaypointsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final current = appState.poslatlng();
    Distance distance = new Distance();


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
            leading: Icon(Icons.favorite),
            title: Text(item.name),
            subtitle: Text(item.latlon + "\n" +
                asLocalTime(item.timestamp)
                + " → ${(distance(current, item.toLatLng()) / 1000).toStringAsFixed(1)} km"
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

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.waypoint, required this.wpindex });

  final Waypoint waypoint;
  final int wpindex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waypoint Details'),
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