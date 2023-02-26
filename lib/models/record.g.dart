// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordAdapter extends TypeAdapter<Record> {
  @override
  final int typeId = 0;

  @override
  Record read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Record()
      ..amount = fields[1] as String
      ..timestamp = fields[2] as int
      ..createTime = fields[3] as DateTime
      ..packageName = fields[4] as String
      ..appName = fields[5] as String
      ..notificationText = fields[6] as String
      ..notificationTitle = fields[7] as String
      ..uid = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer
      ..writeByte(8)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.createTime)
      ..writeByte(4)
      ..write(obj.packageName)
      ..writeByte(5)
      ..write(obj.appName)
      ..writeByte(6)
      ..write(obj.notificationText)
      ..writeByte(7)
      ..write(obj.notificationTitle)
      ..writeByte(8)
      ..write(obj.uid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
