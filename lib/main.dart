import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:da_project_1/app.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';
import 'package:da_project_1/services/local_commodity_cache.dart';
import 'package:da_project_1/services/offline_auth_service.dart';
import 'package:da_project_1/services/data_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize local storage (Hive)
  await ProfilingStorageService().init();
  // Initialize commodity cache for offline master data (loads from local storage only, does not sync)
  await LocalCommodityCache().init();
  // Initialize offline auth service
  await OfflineAuthService().initialize();
  // Initialize data sync service for manual sync
  await DataSyncService().initialize();
  // NOTE: Data sync is manual — user clicks "Sync" button to upload profiling data
  // NOTE: Commodity sync is now lazy-loaded when profiling steps open to avoid startup lag and permission errors
  runApp(const MyApp());
}