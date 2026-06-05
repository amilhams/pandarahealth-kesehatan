import 'dart:convert';

class FoodItem {
  final String? foodId;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int water; // in ml
  final String serving;

  FoodItem({
    this.foodId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.water = 0,
    required this.serving,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'water': water,
      'serving': serving,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      foodId: map['foodId'],
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
      water: map['water'] ?? 0,
      serving: map['serving'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FoodItem.fromJson(String source) => FoodItem.fromMap(json.decode(source));
}
