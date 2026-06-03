import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/data/models/hive_models.dart';
import 'core/data/models/weekly_report_model.dart';
import 'core/data/services/report_service.dart';
//import 'core/data/services/seed_data_service.dart';//

import 'core/data/repositories/health_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MoodRecordAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SleepRecordAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(VitalsRecordAdapter());
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(NutritionRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(SymptomRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(WeeklyReportModelAdapter());
  }

  // Open Boxes
  await Future.wait([
    Hive.openBox<UserModel>('user_box'),
    Hive.openBox<MoodRecord>('mood_box'),
    Hive.openBox<SleepRecord>('sleep_box'),
    Hive.openBox<VitalsRecord>('vitals_box'),
    Hive.openBox<NutritionRecord>('nutrition_box'),
    Hive.openBox<SymptomRecord>('symptom_box'),
    Hive.openBox('settings_box'),
    Hive.openBox<WeeklyReportModel>('weekly_reports'),
  ]);

  await ReportService().init();
  // await SeedDataService().seedAll();

  // Background Sync from Firestore to Hive (menggunakan UID)
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    HealthRepository().syncFromFirestore(uid).catchError((e) {
      debugPrint("Failed to sync from Firestore: $e");
    });
  }

  runApp(const ProviderScope(child: PandaraHealthApp()));
}

class PandaraHealthApp extends StatelessWidget {
  const PandaraHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pandara Health',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
