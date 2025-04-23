import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/bluetooth_device_model.dart';

class BluetoothRepository {
  // Singleton pattern
  static final BluetoothRepository _instance = BluetoothRepository._internal();
  factory BluetoothRepository() => _instance;
  BluetoothRepository._internal();

  // Streams
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Device related properties
  BluetoothDevice? _selectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // Check permissions
  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    return !statuses.values.any((status) => status.isDenied);
  }

  // Check if bluetooth is available and turned on
  Future<bool> isBluetoothAvailable() async {
    return await FlutterBluePlus.isAvailable;
  }

  // Get bluetooth state
  Future<BluetoothAdapterState> getBluetoothState() async {
    return await FlutterBluePlus.adapterState.first;
  }

  // Setup bluetooth state listener
  Stream<BluetoothAdapterState> getBluetoothStateStream() {
    return FlutterBluePlus.adapterState;
  }

  // Start scanning for devices
  Future<void> startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  // Get scan results stream
  Stream<List<BluetoothDeviceModel>> getScanResults() {
    return FlutterBluePlus.scanResults.map(
      (results) =>
          results
              .where((result) => result.device.name.isNotEmpty)
              .map((result) => BluetoothDeviceModel(device: result.device, rssi: result.rssi))
              .toList(),
    );
  }

  // Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _selectedDevice = device;

      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            return true;
          }
        }
      }

      return false; // No writable characteristic found
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Get connection state stream
  Stream<BluetoothConnectionState>? getConnectionState() {
    return _selectedDevice?.connectionState;
  }

  // Send command to device
  Future<bool> sendCommand(String command) async {
    if (_writeCharacteristic == null) {
      return false;
    }

    try {
      await _writeCharacteristic!.write(utf8.encode(command));
      return true;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    if (_selectedDevice != null) {
      await _selectedDevice!.disconnect();
      _selectedDevice = null;
      _writeCharacteristic = null;
    }
  }

  // Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    disconnect();
  }

  // Get current connected device
  BluetoothDevice? get connectedDevice => _selectedDevice;

  // Check if we have a writable characteristic
  bool get hasWriteCharacteristic => _writeCharacteristic != null;
}
