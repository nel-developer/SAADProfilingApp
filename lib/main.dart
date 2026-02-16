import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:da_project_1/app.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize local storage (Hive)
  await ProfilingStorageService().init();
  runApp(const MyApp());
}