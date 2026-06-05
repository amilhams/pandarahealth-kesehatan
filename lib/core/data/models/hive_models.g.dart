// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      name: fields[0] as String,
      email: fields[1] as String,
      password: fields[3] as String,
      profilePic: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.profilePic)
      ..writeByte(3)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodRecordAdapter extends TypeAdapter<MoodRecord> {
  @override
  final int typeId = 1;

  @override
  MoodRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodRecord(
      date: fields[0] as DateTime,
      mood: fields[1] as String,
      note: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MoodRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.mood)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SleepRecordAdapter extends TypeAdapter<SleepRecord> {
  @override
  final int typeId = 2;

  @override
  SleepRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepRecord(
      date: fields[0] as DateTime,
      hours: fields[1] as double,
      quality: fields[2] as String,
      isRefreshed: fields[3] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SleepRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.hours)
      ..writeByte(2)
      ..write(obj.quality)
      ..writeByte(3)
      ..write(obj.isRefreshed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VitalsRecordAdapter extends TypeAdapter<VitalsRecord> {
  @override
  final int typeId = 3;

  @override
  VitalsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VitalsRecord(
      date: fields[0] as DateTime,
      heartRate: fields[1] as int,
      steps: fields[2] as int,
      weight: fields[3] as double,
      height: fields[4] as int?,
      oxygen: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, VitalsRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.heartRate)
      ..writeByte(2)
      ..write(obj.steps)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.oxygen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VitalsRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutritionRecordAdapter extends TypeAdapter<NutritionRecord> {
  @override
  final int typeId = 4;

  @override
  NutritionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionRecord(
      date: fields[0] as DateTime,
      calories: fields[1] as int,
      mealType: fields[2] as String,
      protein: fields[3] as int,
      carbs: fields[4] as int,
      fat: fields[5] as int,
      selectedFoods: (fields[6] as List?)?.cast<String>(),
      water: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.mealType)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.selectedFoods)
      ..writeByte(7)
      ..write(obj.water);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SymptomRecordAdapter extends TypeAdapter<SymptomRecord> {
  @override
  final int typeId = 5;

  @override
  SymptomRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymptomRecord(
      date: fields[0] as DateTime,
      symptoms: (fields[1] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, SymptomRecord obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.symptoms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
