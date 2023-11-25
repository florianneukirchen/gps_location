import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'myapp.dart';
import 'locationwidgets.dart';

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
            ShowLocation(position: appState.currentposition!),
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

