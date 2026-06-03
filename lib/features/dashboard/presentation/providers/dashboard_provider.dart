import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/repositories/health_repository.dart';
import 'triage_provider.dart';

final dashboardStatsProvider = Provider((ref) {
  ref.watch(triageDataRefreshProvider);
  final repository = ref.watch(healthRepositoryProvider);
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final end = today;

  // Fetch range data
  final vitals = repository.getVitalsByRange(start, end);
  final sleeps = repository.getSleepByRange(start, end);
  final totalCalories = repository.getTotalCaloriesToday();

  // Average sleep hours over the last 7 days
  double avgSleep = 0.0;
  if (sleeps.isNotEmpty) {
    avgSleep = sleeps.fold<double>(0.0, (s, r) => s + r.hours) / sleeps.length;
  } else {
    final allSleeps = repository.getAllSleep();
    if (allSleeps.isNotEmpty) {
      avgSleep = allSleeps.first.hours;
    }
  }

  // Average vitals over the last 7 days
  int avgHR = 0;
  int avgSteps = 0;
  int? avgOxygen;

  if (vitals.isNotEmpty) {
    avgHR = (vitals.fold<int>(0, (s, r) => s + r.heartRate) / vitals.length).round();
    avgSteps = (vitals.fold<int>(0, (s, r) => s + r.steps) / vitals.length).round();
    
    final oxygenList = vitals.map((v) => v.oxygen).whereType<int>();
    if (oxygenList.isNotEmpty) {
      avgOxygen = (oxygenList.fold<int>(0, (s, val) => s + val) / oxygenList.length).round();
    }
  } else {
    final latestVitals = repository.getLatestVitals();
    avgHR = latestVitals?.heartRate ?? 0;
    avgSteps = latestVitals?.steps ?? 0;
    avgOxygen = latestVitals?.oxygen;
  }
  
  final latestVitals = repository.getLatestVitals();
  final latestWeight = latestVitals?.weight ?? 0.0;

  return DashboardStats(
    calories: totalCalories,
    steps: avgSteps,
    heartRate: avgHR,
    sleepHours: avgSleep,
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
