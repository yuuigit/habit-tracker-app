// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitRecordAdapter extends TypeAdapter<HabitRecord> {
  @override
  final int typeId = 1;

  @override
  HabitRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitRecord()
      ..id = fields[0] as String
      ..habitId = fields[1] as String
      ..date = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HabitRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
