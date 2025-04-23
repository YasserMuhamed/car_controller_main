import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel {
  final BluetoothDevice device;
  final int rssi;

  BluetoothDeviceModel({required this.device, required this.rssi});

  String get name => device.name.isNotEmpty ? device.name : 'Unknown Device';
  String get id => device.id.toString();
  bool get hasName => device.name.isNotEmpty;
}
