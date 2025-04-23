import 'package:flutter/material.dart';
import '../../data/models/bluetooth_device_model.dart';

class DeviceListItem extends StatelessWidget {
  final BluetoothDeviceModel device;
  final VoidCallback onTap;

  const DeviceListItem({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text('Signal: ${device.rssi} dBm | ID: ${device.id}'),
      leading: const Icon(Icons.bluetooth),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
