import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed to enforce portrait
import 'myapp.dart';

void main() {
  // Force portrait orientation
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}
