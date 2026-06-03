import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/data/models/hive_models.dart';
import '../../../../core/data/repositories/health_repository.dart';

// Penambahan tipe 'empty' untuk menangani kondisi data kosong / pengguna baru
enum TriageType { critical, warning, habits, safe, empty }

class TriageBanner {
  final String title;
  final String description;
  final String category; // Untuk filter kategori konsultasi
  final String actionText;

  TriageBanner({
    required this.title,
    required this.description,
    required this.category,
    required this.actionText,
  });
}

class TriageResult {
  final TriageType type;
  final String title;
  final String description;
  final String? recommendedSpecialty; // Rujukan utama spesialis
  final List<TriageBanner> banners; // Untuk Lapis 3
  final int totalPoints;
  final Map<String, int> basketPoints; // Rincian poin per keranjang

  TriageResult({
    required this.type,
    required this.title,
    required this.description,
    this.recommendedSpecialty,
    this.banners = const [],
    this.totalPoints = 0,
    this.basketPoints = const {},
  });
}

String _triageWarningKeyForToday() {
  final now = DateTime.now();
  return 'triage_warning_dismissed_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
}

String _triageCriticalKeyForToday() {
  final now = DateTime.now();
  return 'triage_critical_acknowledged_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
}

class TriageWarningDismissedNotifier extends StateNotifier<bool> {
  TriageWarningDismissedNotifier() : super(false) {
    final box = Hive.box('settings_box');
    state = box.get(_triageWarningKeyForToday(), defaultValue: false) as bool;
  }

  void dismiss() {
    final box = Hive.box('settings_box');
    box.put(_triageWarningKeyForToday(), true);
    state = true;
  }
}

class TriageCriticalAcknowledgedNotifier extends StateNotifier<bool> {
  TriageCriticalAcknowledgedNotifier() : super(false) {
    final box = Hive.box('settings_box');
    state = box.get(_triageCriticalKeyForToday(), defaultValue: false) as bool;
  }

  void acknowledge() {
    final box = Hive.box('settings_box');
    box.put(_triageCriticalKeyForToday(), true);
    state = true;
  }
}

class TriageDataRefreshNotifier extends StateNotifier<int> {
  final List<void Function()> _removeListeners = [];

  TriageDataRefreshNotifier() : super(0) {
    void attach(Box box) {
      void listener() {
        state = state + 1;
      }

      box.listenable().addListener(listener);
      _removeListeners.add(() => box.listenable().removeListener(listener));
    }

    attach(Hive.box<VitalsRecord>('vitals_box'));
    attach(Hive.box<SleepRecord>('sleep_box'));
    attach(Hive.box<MoodRecord>('mood_box'));
    attach(Hive.box<NutritionRecord>('nutrition_box'));
    attach(Hive.box<SymptomRecord>('symptom_box'));
  }

  @override
  void dispose() {
    for (final remove in _removeListeners) {
      remove();
    }
    super.dispose();
  }
}

final triageWarningDismissedProvider =
    StateNotifierProvider<TriageWarningDismissedNotifier, bool>(
      (ref) => TriageWarningDismissedNotifier(),
    );

final triageCriticalAcknowledgedProvider =
    StateNotifierProvider<TriageCriticalAcknowledgedNotifier, bool>(
      (ref) => TriageCriticalAcknowledgedNotifier(),
    );

final triageDataRefreshProvider =
    StateNotifierProvider<TriageDataRefreshNotifier, int>(
      (ref) => TriageDataRefreshNotifier(),
    );

final triageResultProvider = Provider<TriageResult>((ref) {
  ref.watch(triageDataRefreshProvider);
  final repository = ref.watch(healthRepositoryProvider);

  // Helper date checker
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // 1. Ambil data hari ini
  final now = DateTime.now();

  // Vitals
  final latestVitals = repository.getLatestVitals();
  final VitalsRecord? todayVitals =
      (latestVitals != null && isToday(latestVitals.date))
      ? latestVitals
      : null;

  // Mood
  final moodRecords = repository.getAllMoods();
  final MoodRecord? todayMood =
      moodRecords.isNotEmpty && isToday(moodRecords.first.date)
      ? moodRecords.first
      : null;

  // Sleep
  final sleepRecords = repository.getAllSleep();
  final SleepRecord? todaySleep =
      sleepRecords.isNotEmpty && isToday(sleepRecords.first.date)
      ? sleepRecords.first
      : null;

  // Symptoms
  final symptomBox = Hive.box<SymptomRecord>('symptom_box');
  final SymptomRecord? todaySymptom = symptomBox.values.isEmpty
      ? null
      : symptomBox.values.cast<SymptomRecord?>().firstWhere(
          (rec) => rec != null && isToday(rec.date),
          orElse: () => null,
        );

  // Nutrition
  final todayNutrition = repository.getDailyNutrition(now);

  // ==========================================================================
  // KONDISI PENGAMAN (GUARD CLAUSE): PROTEKSI USER BARU / DATA KOSONG HARI INI
  // ==========================================================================
  if (todayVitals == null &&
      todayMood == null &&
      todaySleep == null &&
      todaySymptom == null &&
      todayNutrition.isEmpty) {
    return TriageResult(
      type: TriageType.empty,
      title: 'Belum Ada Data Hari Ini',
      description:
          'Silakan isi data kesehatan Anda hari ini melalui menu Tracker untuk melihat analisis triase kesehatan.',
    );
  }

  // ==========================================
  // LAPIS 1: PENGECEKAN KRITIS (RED FLAG)
  // ==========================================
  if (todayVitals != null) {
    // Cek SpO2
    if (todayVitals.oxygen != null && todayVitals.oxygen! < 92) {
      return TriageResult(
        type: TriageType.critical,
        title: 'Kondisi Darurat Paru!',
        description:
            'Tingkat saturasi oksigen (SpO2) Anda sangat rendah (${todayVitals.oxygen}%). Segera ke IGD atau hubungi Dokter Paru.',
        recommendedSpecialty: 'Paru',
      );
    }
    // Cek Detak Jantung
    if (todayVitals.heartRate < 50 || todayVitals.heartRate > 120) {
      return TriageResult(
        type: TriageType.critical,
        title: 'Kondisi Darurat Jantung!',
        description:
            'Detak jantung Anda tidak normal (${todayVitals.heartRate} BPM). Segera ke IGD atau hubungi Dokter Jantung.',
        recommendedSpecialty: 'Jantung',
      );
    }
  }

  // Cek Skala Keparahan Gejala > 8 (Skala 9 dan 10 memicu Lapis 1)
  if (todaySymptom != null && todaySymptom.symptoms.isNotEmpty) {
    final maxSeverity = todaySymptom.symptoms.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );
    if (maxSeverity > 8.0) {
      final severeSymptoms = todaySymptom.symptoms.entries
          .where((e) => e.value > 8.0)
          .map((e) => e.key)
          .join(', ');
      return TriageResult(
        type: TriageType.critical,
        title: 'Gejala Kritis Terdeteksi!',
        description:
            'Sistem mendeteksi gejala dengan tingkat keparahan tinggi ($severeSymptoms). Segera ke IGD atau hubungi Dokter Umum.',
        recommendedSpecialty: 'Umum',
      );
    }
  }

  // ==========================================
  // LAPIS 2: AKUMULASI POIN & DOMINANSI
  // ==========================================
  int pointsPulmonologi = 0;
  int pointsMentalTidur = 0;
  int pointsUmum = 0;

  // Evaluasi Gejala Paru (Pulmonologi)
  if (todaySymptom != null) {
    final pulmonologiSymptoms = todaySymptom.symptoms.entries.where(
      (e) =>
          e.key == 'Batuk' ||
          e.key == 'Sesak Napas' ||
          e.key == 'Sakit Tenggorokan',
    );
    if (pulmonologiSymptoms.isNotEmpty) {
      pointsPulmonologi += pulmonologiSymptoms.length * 15;
      final maxPulmoSeverity = pulmonologiSymptoms
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);
      pointsPulmonologi += (maxPulmoSeverity * 5).round();
    }
  }

  // Evaluasi Mood & Tidur (MentalTidur)
  if (todayMood != null) {
    if (todayMood.mood == 'Sad' || todayMood.mood == 'Angry') {
      pointsMentalTidur += 20;
    }
  }
  if (todaySleep != null) {
    if (todaySleep.quality == 'Buruk') {
      pointsMentalTidur += 30;
    }
    if (todaySleep.hours < 4.0) {
      pointsMentalTidur += 25;
    }
  }
  if (todaySymptom != null && todaySymptom.symptoms.containsKey('Kelelahan')) {
    final fatigueSeverity = todaySymptom.symptoms['Kelelahan'] ?? 0.0;
    pointsMentalTidur += 15 + (fatigueSeverity * 5).round();
  }

  // Evaluasi Penyakit Dalam / Umum
  if (todaySymptom != null) {
    // Filter gejala umum (semua gejala selain pulmonologi & kelelahan)
    final umumSymptoms = todaySymptom.symptoms.entries.where(
      (e) =>
          e.key != 'Batuk' &&
          e.key != 'Sesak Napas' &&
          e.key != 'Sakit Tenggorokan' &&
          e.key != 'Kelelahan',
    );
    if (umumSymptoms.isNotEmpty) {
      pointsUmum += umumSymptoms.length * 15;
      final maxUmumSeverity = umumSymptoms
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);
      pointsUmum += (maxUmumSeverity * 5).round();
    }
  }

  final int totalPoints = pointsPulmonologi + pointsMentalTidur + pointsUmum;

  // Ambil keparahan gejala maksimal untuk memicu Lapis 2 secara otomatis jika di rentang 6-8
  double maxSymptomSeverityForLapis2 = 0.0;
  if (todaySymptom != null && todaySymptom.symptoms.isNotEmpty) {
    maxSymptomSeverityForLapis2 = todaySymptom.symptoms.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );
  }

  if (totalPoints >= 100 ||
      (maxSymptomSeverityForLapis2 >= 6.0 &&
          maxSymptomSeverityForLapis2 <= 8.0)) {
    // Tentukan dominansi
    String recommendedSpec = 'Umum';
    String descText = '';

    if (pointsMentalTidur >= pointsPulmonologi &&
        pointsMentalTidur >= pointsUmum) {
      recommendedSpec = 'Mental';
      descText =
          'Sistem mendeteksi tingkat kelelahan emosional dan kualitas tidur Anda sangat buruk secara akumulatif. Disarankan berkonsultasi dengan Psikolog/Psikiater.';
    } else if (pointsPulmonologi >= pointsMentalTidur &&
        pointsPulmonologi >= pointsUmum) {
      recommendedSpec = 'Paru';
      descText =
          'Sistem mendeteksi akumulasi gejala pernapasan Anda meningkat. Disarankan berkonsultasi dengan Dokter Paru.';
    } else {
      recommendedSpec = 'Umum';
      descText =
          'Sistem mendeteksi akumulasi gejala fisik Anda hari ini cukup tinggi. Disarankan berkonsultasi dengan Dokter Umum.';
    }

    return TriageResult(
      type: TriageType.warning,
      title: 'Peringatan Kesehatan Terdeteksi!',
      description: descText,
      recommendedSpecialty: recommendedSpec,
      totalPoints: totalPoints,
      basketPoints: {
        'Pulmonologi': pointsPulmonologi,
        'MentalTidur': pointsMentalTidur,
        'Umum': pointsUmum,
      },
    );
  }

  // ==========================================
  // LAPIS 3: PENGECEKAN PER-FAKTOR (HABITS)
  // ==========================================
  final List<TriageBanner> habitsBanners = [];

  // A. Cek Nutrisi (Telat makan)
  final currentHour = now.hour;

  // Definisikan tipe makan yang terinput hari ini
  final loggedMealTypes = todayNutrition.map((rec) => rec.mealType).toSet();

  // Batas jam & cek log
  if (currentHour >= 10 && !loggedMealTypes.contains('Sarapan')) {
    habitsBanners.add(
      TriageBanner(
        title: 'Perbaiki Pola Makan',
        description:
            'Jangan telat makan ya! Sistem mendeteksi kamu melewatkan jam makan Sarapan.',
        category: 'Gizi',
        actionText: 'Tanya Ahli Gizi',
      ),
    );
  }
  if (currentHour >= 14 && !loggedMealTypes.contains('Makan Siang')) {
    habitsBanners.add(
      TriageBanner(
        title: 'Perbaiki Pola Makan',
        description:
            'Jangan telat makan ya! Sistem mendeteksi kamu melewatkan jam makan Siang.',
        category: 'Gizi',
        actionText: 'Tanya Ahli Gizi',
      ),
    );
  }
  if (currentHour >= 20 && !loggedMealTypes.contains('Makan Malam')) {
    habitsBanners.add(
      TriageBanner(
        title: 'Perbaiki Pola Makan',
        description:
            'Jangan telat makan ya! Sistem mendeteksi kamu melewatkan jam makan Malam.',
        category: 'Gizi',
        actionText: 'Tanya Ahli Gizi',
      ),
    );
  }

  // B. Cek Tidur
  if (todaySleep != null) {
    if (todaySleep.hours < 5.0 || todaySleep.quality == 'Buruk') {
      habitsBanners.add(
        TriageBanner(
          title: 'Istirahat Kurang Optimal',
          description:
              'Tidur Anda kurang dari 5 jam atau kualitasnya buruk. Konsultasikan pola tidur Anda.',
          category: 'Umum',
          actionText: 'Konsultasi Tidur',
        ),
      );
    }
  }

  // C. Cek Mood
  if (todayMood != null) {
    if (todayMood.mood == 'Sad' || todayMood.mood == 'Angry') {
      habitsBanners.add(
        TriageBanner(
          title: 'Butuh Teman Cerita?',
          description:
              'Suasana hati Anda hari ini terdeteksi kurang baik. Jangan ragu konsultasi.',
          category: 'Mental',
          actionText: 'Tanya Psikolog',
        ),
      );
    }
  }

  if (habitsBanners.isNotEmpty) {
    return TriageResult(
      type: TriageType.habits,
      title: 'Rekomendasi Kebiasaan',
      description:
          'Beberapa kebiasaan harian Anda hari ini memerlukan perhatian.',
      banners: habitsBanners,
    );
  }

  // ==========================================
  // LAPIS 4: AMAN (SAFE STATE)
  // ==========================================
  return TriageResult(
    type: TriageType.safe,
    title: 'Kondisi Aman',
    description: 'Hebat! Kondisimu hari ini sangat baik!',
  );
});
