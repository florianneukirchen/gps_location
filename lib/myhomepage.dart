import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mypositionpage.dart';
import 'waypointspage.dart';
import 'myapp.dart';



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

    var appState = context.watch<MyAppState>();


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
              icon: Badge(
                label: Text(appState.waypoints.length.toString()),
                child: Icon(Icons.edit_location_alt_outlined),
              ),
              label: "Waypoints"
          ),
        ],
      ),
      body: page,
    );
  }
}