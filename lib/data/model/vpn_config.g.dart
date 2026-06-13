// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'vpn_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VpnConfigAdapter extends TypeAdapter<VpnConfig> {
  @override
  final int typeId = 1;

  @override
  VpnConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VpnConfig(
      protocol: fields[0] as VpnProtocol,
      label: fields[1] as String,
      autoConnect: fields[2] as bool,
      wgConfigBlock: fields[3] as String?,
      ovpnConfigBlock: fields[4] as String?,
      ovpnUsername: fields[5] as String?,
      ovpnPassword: fields[6] as String?,
      serverAddress: fields[7] as String?,
      username: fields[8] as String?,
      password: fields[9] as String?,
      ipsecPsk: fields[10] as String?,
      ipsecCaCert: fields[11] as String?,
      ipsecClientCert: fields[12] as String?,
      ipsecClientKey: fields[13] as String?,
      ikev2Identity: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VpnConfig obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.protocol)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.autoConnect)
      ..writeByte(3)
      ..write(obj.wgConfigBlock)
      ..writeByte(4)
      ..write(obj.ovpnConfigBlock)
      ..writeByte(5)
      ..write(obj.ovpnUsername)
      ..writeByte(6)
      ..write(obj.ovpnPassword)
      ..writeByte(7)
      ..write(obj.serverAddress)
      ..writeByte(8)
      ..write(obj.username)
      ..writeByte(9)
      ..write(obj.password)
      ..writeByte(10)
      ..write(obj.ipsecPsk)
      ..writeByte(11)
      ..write(obj.ipsecCaCert)
      ..writeByte(12)
      ..write(obj.ipsecClientCert)
      ..writeByte(13)
      ..write(obj.ipsecClientKey)
      ..writeByte(14)
      ..write(obj.ikev2Identity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VpnProtocolAdapter extends TypeAdapter<VpnProtocol> {
  @override
  final int typeId = 2;

  @override
  VpnProtocol read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VpnProtocol.wireguard;
      case 1:
        return VpnProtocol.openVpn;
      case 2:
        return VpnProtocol.ikev2Eap;
      case 3:
        return VpnProtocol.ikev2Psk;
      case 4:
        return VpnProtocol.l2tpIpsecPsk;
      case 5:
        return VpnProtocol.pptp;
      default:
        return VpnProtocol.wireguard;
    }
  }

  @override
  void write(BinaryWriter writer, VpnProtocol obj) {
    switch (obj) {
      case VpnProtocol.wireguard:
        writer.writeByte(0);
      case VpnProtocol.openVpn:
        writer.writeByte(1);
      case VpnProtocol.ikev2Eap:
        writer.writeByte(2);
      case VpnProtocol.ikev2Psk:
        writer.writeByte(3);
      case VpnProtocol.l2tpIpsecPsk:
        writer.writeByte(4);
      case VpnProtocol.pptp:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnProtocolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
