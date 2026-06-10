import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/repositories/health_repository.dart';
import 'triage_provider.dart';

final dashboardStatsProvider = Provider((ref) {
  ref.watch(triageDataRefreshProvider);
  final repository = ref.watch(healthRepositoryProvider);
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Fetch range data only for today
  final vitals = repository.getVitalsByRange(today, today);
  final sleeps = repository.getSleepByRange(today, today);
  final totalCalories = repository.getTotalCaloriesToday();

  // Sum sleep hours over today
  double totalSleep = 0.0;
  if (sleeps.isNotEmpty) {
    totalSleep = sleeps.fold<double>(0.0, (s, r) => s + r.hours);
  }

  // Calculate stats for today
  int avgHR = 0;
  int totalSteps = 0;
  int? avgOxygen;

  if (vitals.isNotEmpty) {
    avgHR = (vitals.fold<int>(0, (s, r) => s + r.heartRate) / vitals.length).round();
    totalSteps = vitals.fold<int>(0, (s, r) => s + r.steps);
    
    final oxygenList = vitals.map((v) => v.oxygen).whereType<int>();
    if (oxygenList.isNotEmpty) {
      avgOxygen = (oxygenList.fold<int>(0, (s, val) => s + val) / oxygenList.length).round();
    }
  }
  
  // Weight can remain as latest weight overall to ensure BMI calculations still work
  final latestVitals = repository.getLatestVitals();
  final latestWeight = latestVitals?.weight ?? 0.0;

  return DashboardStats(
    calories: totalCalories,
    steps: totalSteps,
    heartRate: avgHR,
    sleepHours: totalSleep,
    weight: latestWeight,
    oxygen: avgOxygen,
  );
});

class DashboardStats {
  final int calories;
  final int steps;
  final int heartRate;
  final double sleepHours;
  final double weight;
  final int? oxygen;

  DashboardStats({
    required this.calories,
    required this.steps,
    required this.heartRate,
    required this.sleepHours,
    required this.weight,
    this.oxygen,
  });
}
