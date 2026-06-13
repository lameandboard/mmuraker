// mmuraker – a community derivative app inspired by mobileraker.
// mobileraker is Copyright (c) 2024 Patrick Schmidt (Mobileraker License v2).
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

part of 'machine.dart';

class MachineAdapter extends TypeAdapter<Machine> {
  @override
  int get typeId => 0;

  @override
  Machine read(BinaryReader reader) {
    return Machine(
      id: reader.read() as String,
      name: reader.read() as String,
      httpUrl: reader.read() as String,
      wsUrl: reader.read() as String,
      port: reader.read() as int,
      apiKey: reader.read() as String?,
      vpnConfig: reader.read() as VpnConfig?,
      lastKnownState: reader.read() as String,
      webcamUrl: reader.read() as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Machine obj) {
    writer
      ..write(obj.id)
      ..write(obj.name)
      ..write(obj.httpUrl)
      ..write(obj.wsUrl)
      ..write(obj.port)
      ..write(obj.apiKey)
      ..write(obj.vpnConfig)
      ..write(obj.lastKnownState)
      ..write(obj.webcamUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
