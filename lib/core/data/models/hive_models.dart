import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String email;
  @HiveField(2)
  String? profilePic;
  @HiveField(3)
  String password;

  UserModel({
    required this.name,
    required this.email,
    required this.password,
    this.profilePic,
  });

  @override
  String toString() => 'UserModel(name: $name, email: $email, password: $password)';
}

@HiveType(typeId: 1)
class MoodRecord extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String mood; // happy, neutral, sad, etc.
  @HiveField(2)
  String note;

  MoodRecord({required this.date, required this.mood, required this.note});

  @override
  String toString() => 'MoodRecord(date: $date, mood: $mood, note: $note)';
}

@HiveType(typeId: 2)
class SleepRecord extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  double hours;
  @HiveField(2)
  String quality;
  @HiveField(3)
  bool? isRefreshed;

  SleepRecord({
    required this.date, 
    required this.hours, 
    required this.quality, 
    this.isRefreshed
  });

  @override
  String toString() => 'SleepRecord(date: $date, hours: $hours, quality: $quality, refreshed: ${isRefreshed ?? 'N/A'})';
}

@HiveType(typeId: 3)
class VitalsRecord extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  int heartRate;
  @HiveField(2)
  int steps;
  @HiveField(3)
  double weight;
  @HiveField(4)
  int? height;
  @HiveField(5)
  int? oxygen;

  VitalsRecord({
    required this.date,
    required this.heartRate,
    required this.steps,
    required this.weight,
    this.height,
    this.oxygen,
  });

  @override
  String toString() => 'VitalsRecord(date: $date, heartRate: $heartRate, steps: $steps, weight: $weight, height: $height, oxygen: $oxygen)';
}

@HiveType(typeId: 4)
class NutritionRecord extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  int calories;
  @HiveField(2)
  String mealType; // Breakfast, Lunch, Dinner, Snack
  @HiveField(3)
  int protein;
  @HiveField(4)
  int carbs;
  @HiveField(5)
  int fat;
  @HiveField(6)
  List<String>? selectedFoods;
  @HiveField(7)
  int? water; // in ml

  NutritionRecord({
    required this.date,
    required this.calories,
    required this.mealType,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.selectedFoods,
    this.water = 0,
  });
}

@HiveType(typeId: 5)
class SymptomRecord extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  Map<String, double> symptoms; // { 'Sakit Kepala': 8.0, 'Demam': 4.0 }

  SymptomRecord({required this.date, required this.symptoms});

  @override
  String toString() => 'SymptomRecord(date: $date, symptoms: $symptoms)';
}
