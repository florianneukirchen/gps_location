import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'myapp.dart';


class WaypointsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

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
          key: Key(item.timestamp.toString()),
          onDismissed: (direction) {
            appState.deleteWaypoint(index);
          },
          background: Container(color: Colors.red),
          child: ListTile(
            leading: Icon(Icons.favorite),
            title: Text(item.name),
            subtitle: Text(item.latlon + "\n" +
                asLocalTime(item.timestamp)),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
