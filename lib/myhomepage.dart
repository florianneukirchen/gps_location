import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'locationwidgets.dart';
import 'mypositionpage.dart';
import 'waypointspage.dart';
import 'myapp.dart';
import 'mapwidget.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Init index of Navigation (current page)
  var selectedIndex = 0;

  // Confirmation dialog to delete waypoints
  void _confirmDeleteWaypoints() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Waypoints"),
          content: Text("Are you sure you want to delete all waypoints?"),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Delete All"),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<MyAppState>(context, listen: false).deleteAllWaypoints();
              },
            ),
          ],
        );
      }
    );
  }

  void _sharewaypoints() async {
    final filepath = await Provider.of<MyAppState>(context, listen: false).storage.filepath();
    Share.shareXFiles([XFile(filepath)], text: 'Great picture');
  }


  // For the switching in the dialog
  //SortOrder _selectedSortOrder = SortOrder.nameAscending;

  void _showSortOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sort Order for Waypoints"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildRadioListTile('Time Ascending', SortOrder.timeAscending),
              _buildRadioListTile('Time Descending', SortOrder.timeDescending),
              _buildRadioListTile('Name Ascending', SortOrder.nameAscending),
              _buildRadioListTile('Name Descending', SortOrder.nameDescending),
              _buildRadioListTile('Distance Ascending', SortOrder.distanceAscending),
              _buildRadioListTile('Distance Descending', SortOrder.distanceDescending),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              }
            )
          ]
        );
      },
    );
  }

  Widget _buildRadioListTile(String title, SortOrder value) {
    var appState = context.watch<MyAppState>();
    return RadioListTile<SortOrder>(
      title: Text(title),
      value: value,
      groupValue: appState.sortOrder,
      onChanged: (SortOrder? selectedValue) {
        if (selectedValue != null) {
          appState.sortOrder = selectedValue;
          Navigator.of(context).pop();
          // Apply sort order logic here
          appState.sortWaypoints();
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MyPositionPage();
        break;
      case 1:
        page = MyMapPage();
        break;
      case 2:
        page = WaypointsPage();
      default:
        throw UnimplementedError("No widget for selected index");
    }

    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.swap_vert,
              semanticLabel: "sort order",
            ),
            onPressed: _showSortOrderDialog,
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            ListTile(
              title: const Text('Share Current Position'),
              onTap: () {
                Navigator.pop(context);
                final currentposition = Provider.of<MyAppState>(context, listen: false).currentposition;
                if (currentposition != null) {
                  Share.share(asEW_NW(currentposition.latitude, currentposition.longitude), subject: 'My Position');
                } else {
                  var scaffoldmessenger = ScaffoldMessenger.of(context);
                  scaffoldmessenger.showSnackBar(
                      SnackBar(
                        content: Text('Position is not known'),
                      )
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Share Waypoints'),
              onTap: () {
                Navigator.pop(context);
                _sharewaypoints();
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Delete all waypoints'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteWaypoints();
              }),

          ],
        ),
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
              icon: Icon(Icons.map),
              label: "Map",
          ),
          NavigationDestination(
              icon: Badge(
                label: Text(appState.waypoints.length.toString()),
                isLabelVisible: (appState.waypoints.length > 0),
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

class MyMapPage extends StatelessWidget {
  const MyMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [MyMap(linkmarkers: true),]
    );
  }
}