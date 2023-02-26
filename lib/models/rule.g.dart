// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RuleAdapter extends TypeAdapter<Rule> {
  @override
  final int typeId = 1;

  @override
  Rule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rule()
      ..appName = fields[0] as String
      ..packageName = fields[1] as String
      ..callbackUrl = fields[2] as String
      ..matchPattern = fields[3] as String
      ..callbackHttpMethod = fields[4] as String
      ..icon = fields[5] as Uint8List;
  }

  @override
  void write(BinaryWriter writer, Rule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.callbackUrl)
      ..writeByte(3)
      ..write(obj.matchPattern)
      ..writeByte(4)
      ..write(obj.callbackHttpMethod)
      ..writeByte(5)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
