import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Handle reading and writing of Waypoints to disk
class WaypointStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/waypoints.geojson');
  }

  Future<String> readWaypointFile() async {
    final file = await _localFile;
    final contents = await file.readAsString();
    return contents;
  }

  Future<File> writeWaypointFile(contents) async {
    final file = await _localFile;
    return file.writeAsString(contents);
  }

  Future<String> filepath() async {
    final path = await _localPath;
    return '$path/waypoints.geojson';
  }


  Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/settings');
  }

  Future<String> readSettingsFile() async {
    final file = await _settingsFile;
    final contents = await file.readAsString();
    return contents;
  }

  Future<File> writeSettingsFile(contents) async {
    final file = await _settingsFile;
    print("write");
    return file.writeAsString(contents);
  }

}

// https://stackoverflow.com/questions/51807228/writing-to-a-local-json-file-dart-flutter
// https://docs.flutter.dev/cookbook/persistence/reading-writing-files

// https://www.codecentric.de/wissens-hub/blog/geojson-tutorial