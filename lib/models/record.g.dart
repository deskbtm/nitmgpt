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
      ..isAd = fields[1] as bool
      ..adProbability = fields[2] as double
      ..isSpam = fields[3] as bool
      ..spamProbability = fields[4] as double
      ..timestamp = fields[5] as int
      ..createTime = fields[6] as DateTime
      ..packageName = fields[7] as String
      ..appName = fields[8] as String
      ..notificationText = fields[9] as String
      ..notificationTitle = fields[10] as String
      ..uid = fields[11] as String
      ..notificationKey = fields[12] as String
      ..removed = fields[13] as bool;
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer
      ..writeByte(13)
      ..writeByte(1)
      ..write(obj.isAd)
      ..writeByte(2)
      ..write(obj.adProbability)
      ..writeByte(3)
      ..write(obj.isSpam)
      ..writeByte(4)
      ..write(obj.spamProbability)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.createTime)
      ..writeByte(7)
      ..write(obj.packageName)
      ..writeByte(8)
      ..write(obj.appName)
      ..writeByte(9)
      ..write(obj.notificationText)
      ..writeByte(10)
      ..write(obj.notificationTitle)
      ..writeByte(11)
      ..write(obj.uid)
      ..writeByte(12)
      ..write(obj.notificationKey)
      ..writeByte(13)
      ..write(obj.removed);
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
