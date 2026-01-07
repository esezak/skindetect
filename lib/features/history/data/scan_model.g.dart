// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanModelAdapter extends TypeAdapter<ScanModel> {
  @override
  final int typeId = 0;

  @override
  ScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanModel(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      date: fields[2] as DateTime,
      result: (fields[3] as Map).cast<String, double>(),
      rawAiResult: (fields[4] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScanModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.result)
      ..writeByte(4)
      ..write(obj.rawAiResult);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
