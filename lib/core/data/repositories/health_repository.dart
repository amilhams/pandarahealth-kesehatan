import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hive_models.dart';
import 'package:flutter/foundation.dart';

final healthRepositoryProvider = Provider((ref) => HealthRepository());

class HealthRepository {
  // Boxes
  final _userBox = Hive.box<UserModel>('user_box');
  final _moodBox = Hive.box<MoodRecord>('mood_box');
  final _sleepBox = Hive.box<SleepRecord>('sleep_box');
  final _vitalsBox = Hive.box<VitalsRecord>('vitals_box');
  final _nutritionBox = Hive.box<NutritionRecord>('nutrition_box');
  final _symptomBox = Hive.box<SymptomRecord>('symptom_box');

  // --- USER PROFILE ---
  Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user);
    await _userBox.flush();

    // Sync profile to Firestore (menggunakan UID sebagai document key)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': user.name,
        'email': user.email,
        'profilePic': user.profilePic,
      }, SetOptions(merge: true));
    }
  }

  UserModel? getUser() {
    return _userBox.get('current_user');
  }

  // --- MOOD TRACKER ---
  Future<void> addMood(MoodRecord record) async {
    await _moodBox.add(record);
    await _moodBox.flush();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(record.date.toIso8601String())
          .set({
            'date': record.date.toIso8601String(),
            'mood': record.mood,
            'note': record.note,
          });
    }
  }

  List<MoodRecord> getAllMoods() {
    return _moodBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  List<MoodRecord> getMoodsByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _moodBox.values
        .where((m) => !m.date.isBefore(s) && !m.date.isAfter(e))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- SLEEP TRACKER ---
  Future<void> addSleep(SleepRecord record) async {
    await _sleepBox.add(record);
    await _sleepBox.flush();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleeps')
          .doc(record.date.toIso8601String())
          .set({
            'date': record.date.toIso8601String(),
            'hours': record.hours,
            'quality': record.quality,
            'isRefreshed': record.isRefreshed,
          });
    }
  }

  List<SleepRecord> getAllSleep() {
    return _sleepBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SleepRecord> getSleepByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _sleepBox.values
        .where((r) => !r.date.isBefore(s) && !r.date.isAfter(e))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- VITALS TRACKER ---
  Future<void> updateVitals(VitalsRecord record) async {
    await _vitalsBox.add(record);
    await _vitalsBox.flush();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vitals')
          .doc(record.date.toIso8601String())
          .set({
            'date': record.date.toIso8601String(),
            'heartRate': record.heartRate,
            'steps': record.steps,
            'weight': record.weight,
            'height': record.height,
            'oxygen': record.oxygen,
          });
    }
  }

  VitalsRecord? getLatestVitals() {
    if (_vitalsBox.isEmpty) return null;
    return _vitalsBox.values.last;
  }

  List<VitalsRecord> getVitalsByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _vitalsBox.values
        .where((v) => !v.date.isBefore(s) && !v.date.isAfter(e))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- NUTRITION TRACKER ---
  Future<void> addNutrition(NutritionRecord record) async {
    await _nutritionBox.add(record);
    await _nutritionBox.flush();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('nutrition')
          .doc(record.date.toIso8601String())
          .set({
            'date': record.date.toIso8601String(),
            'calories': record.calories,
            'mealType': record.mealType,
            'protein': record.protein,
            'carbs': record.carbs,
            'fat': record.fat,
            'selectedFoods': record.selectedFoods,
          });
    }
  }

  List<NutritionRecord> getDailyNutrition(DateTime date) {
    return _nutritionBox.values
        .where(
          (rec) =>
              rec.date.year == date.year &&
              rec.date.month == date.month &&
              rec.date.day == date.day,
        )
        .toList();
  }

  List<NutritionRecord> getNutritionByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _nutritionBox.values
        .where((n) => !n.date.isBefore(s) && !n.date.isAfter(e))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int getTotalCaloriesToday() {
    final now = DateTime.now();
    final todayRecs = getDailyNutrition(now);
    return todayRecs.fold(0, (total, item) => total + item.calories);
  }

  // --- SYMPTOM TRACKER ---
  Future<void> addSymptom(SymptomRecord record) async {
    await _symptomBox.add(record);
    await _symptomBox.flush();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('symptoms')
          .doc(record.date.toIso8601String())
          .set({
            'date': record.date.toIso8601String(),
            'symptoms': record.symptoms,
          });
    }
  }

  List<SymptomRecord> getSymptomsByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _symptomBox.values
        .where((sym) => !sym.date.isBefore(s) && !sym.date.isAfter(e))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- BMI HELPER ---
  static double? calculateBMI(double weightKg, int heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return null;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Kelebihan Berat';
    return 'Obesitas';
  }

  // --- DYNAMIC WEEKLY REPORT ---

  /// Menghasilkan teks ringkasan mingguan yang dinamis berdasarkan data 7 hari terakhir.
  String generateWeeklyReportText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final end = today;

    // ── Date range ──────────────────────────────────────────────
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    String fmtDate(DateTime d) =>
        '${d.day} ${months[d.month - 1]} ${d.year}';
    final dateRange = '${fmtDate(start)} – ${fmtDate(end)}';

    // ── Sleep ────────────────────────────────────────────────────
    final sleeps = getSleepByRange(start, end);
    String sleepQuality = 'Tidak ada data';
    if (sleeps.isNotEmpty) {
      final avgH = sleeps.fold(0.0, (s, r) => s + r.hours) / sleeps.length;
      final h = avgH.floor();
      final m = ((avgH - h) * 60).round();
      sleepQuality = '${h}j ${m}m';
    }

    // ── Mood ─────────────────────────────────────────────────────
    final moods = getMoodsByRange(start, end);
    String moodStatus = 'Tidak ada data';
    if (moods.isNotEmpty) {
      final count = <String, int>{};
      for (final m in moods) {
        count[m.mood] = (count[m.mood] ?? 0) + 1;
      }
      final dominant = count.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      // Terjemahkan ke label Indonesia
      const labelId = {
        'Angry': 'Marah',
        'Sad': 'Sedih',
        'Neutral': 'Netral',
        'Happy': 'Senang',
        'Great': 'Sangat Baik',
      };
      moodStatus = labelId[dominant] ?? dominant;
    }

    // ── Vitals (Heart Rate & Steps) ───────────────────────────────
    final vitals = getVitalsByRange(start, end);
    String avgHeartRate = 'Tidak ada data';
    String avgSteps = 'Tidak ada data';
    if (vitals.isNotEmpty) {
      final hr = (vitals.fold(0, (s, r) => s + r.heartRate) / vitals.length).round();
      final st = (vitals.fold(0, (s, r) => s + r.steps) / vitals.length).round();
      avgHeartRate = '$hr BPM';
      avgSteps = '$st langkah/hari';
    }

    // ── Nutrition (Kalori) ───────────────────────────────────────
    final nutrition = getNutritionByRange(start, end);
    String avgCalories = 'Tidak ada data';
    if (nutrition.isNotEmpty) {
      // Kelompokkan per hari lalu ambil rata-rata
      final byDay = <String, int>{};
      for (final n in nutrition) {
        final key = '${n.date.year}-${n.date.month}-${n.date.day}';
        byDay[key] = (byDay[key] ?? 0) + n.calories;
      }
      final avg = (byDay.values.fold(0, (s, v) => s + v) / byDay.length).round();
      avgCalories = '$avg kkal/hari';
    }

    return '''📊 RINGKASAN LAPORAN MINGGUAN SAYA ($dateRange):
- 🛌 Rata-rata Tidur: $sleepQuality / malam
- ❤️ Detak Jantung: Rata-rata $avgHeartRate
- 🚶 Aktivitas: Rata-rata $avgSteps
- 🎭 Suasana Hati Dominan: $moodStatus
- 🍽️ Asupan Kalori: Rata-rata $avgCalories''';
  }

  // --- CLOUD FIRESTORE ONLINE SYNC ---
  Future<void> syncFromFirestore(String userUid) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userUid);

    try {
      // 1. Sync Profile
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final user = UserModel(
          name: data['name'] ?? 'User',
          email: data['email'] ?? '',
          password: '',
          profilePic: data['profilePic'],
        );
        await _userBox.put('current_user', user);
      }

      // 2. Sync Vitals
      final vitalsSnap = await userDocRef.collection('vitals').get();
      await _vitalsBox.clear();
      for (final doc in vitalsSnap.docs) {
        final data = doc.data();
        final record = VitalsRecord(
          date: DateTime.parse(data['date'] as String),
          heartRate: data['heartRate'] as int,
          steps: data['steps'] as int,
          weight: (data['weight'] as num).toDouble(),
          height: data['height'] as int?,
          oxygen: data['oxygen'] as int?,
        );
        await _vitalsBox.add(record);
      }

      // 3. Sync Moods
      final moodsSnap = await userDocRef.collection('moods').get();
      await _moodBox.clear();
      for (final doc in moodsSnap.docs) {
        final data = doc.data();
        final record = MoodRecord(
          date: DateTime.parse(data['date'] as String),
          mood: data['mood'] as String,
          note: data['note'] as String,
        );
        await _moodBox.add(record);
      }

      // 4. Sync Sleeps
      final sleepsSnap = await userDocRef.collection('sleeps').get();
      await _sleepBox.clear();
      for (final doc in sleepsSnap.docs) {
        final data = doc.data();
        final record = SleepRecord(
          date: DateTime.parse(data['date'] as String),
          hours: (data['hours'] as num).toDouble(),
          quality: data['quality'] as String,
          isRefreshed: data['isRefreshed'] as bool?,
        );
        await _sleepBox.add(record);
      }

      // 5. Sync Nutrition
      final nutritionSnap = await userDocRef.collection('nutrition').get();
      await _nutritionBox.clear();
      for (final doc in nutritionSnap.docs) {
        final data = doc.data();
        final record = NutritionRecord(
          date: DateTime.parse(data['date'] as String),
          calories: data['calories'] as int,
          mealType: data['mealType'] as String,
          protein: data['protein'] as int,
          carbs: data['carbs'] as int,
          fat: data['fat'] as int,
          selectedFoods: (data['selectedFoods'] as List?)?.cast<String>(),
        );
        await _nutritionBox.add(record);
      }

      // 6. Sync Symptoms
      final symptomsSnap = await userDocRef.collection('symptoms').get();
      await _symptomBox.clear();
      for (final doc in symptomsSnap.docs) {
        final data = doc.data();
        final record = SymptomRecord(
          date: DateTime.parse(data['date'] as String),
          symptoms: Map<String, double>.from(data['symptoms'] as Map),
        );
        await _symptomBox.add(record);
      }

      // Flush to write instantly
      await Future.wait([
        _userBox.flush(),
        _vitalsBox.flush(),
        _moodBox.flush(),
        _sleepBox.flush(),
        _nutritionBox.flush(),
        _symptomBox.flush(),
      ]);
    } catch (e) {
      // Biarkan gagal tanpa merusak aplikasi
      debugPrint("Firestore sync error: $e");
    }
  }
}
