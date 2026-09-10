import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/firebase_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseSetup.initialize();

  runApp(const TontineFacileApp());
}
