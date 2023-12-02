import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'myapp.dart';
import 'locationwidgets.dart';
import 'mapwidget.dart';

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

  void _asyncBtnLoc(scaffoldmessenger) async {
    try {
      await Provider.of<MyAppState>(context, listen: false).updateLocation();
    } on Exception catch (e) {
      var msg = e.toString().substring(11);
      scaffoldmessenger.showSnackBar(
          SnackBar(
            content: Text(msg),
          )
      );
    }
  }

  void _asyncBtnWP(scaffoldmessenger, name) async {
    try {
      await Provider.of<MyAppState>(context, listen: false).addWaypoint(name);
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _asyncBtnLoc(scaffoldmessenger);
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
            // ShowStatus(statusOK: (appState.positionStream != null)),
            ShowLocation(position: appState.currentposition!),
            // SizedBox(height:10),
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
            // SizedBox(height:5),
            ElevatedButton(
              onPressed: () {
                _asyncBtnWP(scaffoldmessenger, textController.text);
                textController.clear();
                // hide keybord
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: const Text('Save Waypoint'),
            ),
            MyMap(),
          ],
        ),
      );
    }
  }
}

