import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:test_car_controller/connected_page.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothHome extends StatefulWidget {
  const BluetoothHome({super.key});

  @override
  _BluetoothHomeState createState() => _BluetoothHomeState();
}

class _BluetoothHomeState extends State<BluetoothHome> {
  bool isScanning = false;
  bool isConnecting = false;
  bool hasError = false;
  String errorMessage = '';
  BluetoothDevice? selectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  bool isConnected = false;

  List<ScanResult> scanResults = [];
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupAdapterListener();
  }

  Future<void> _checkPermissions() async {
    // Check and request relevant permissions for BLE
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    if (statuses.values.any((status) => status.isDenied)) {
      setState(() {
        hasError = true;
        errorMessage = 'Bluetooth permissions denied. Please enable them in settings.';
      });
    } else {
      _checkBluetoothStatus();
    }
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is available and turned on
      if (await FlutterBluePlus.isAvailable == false) {
        setState(() {
          hasError = true;
          errorMessage = 'Bluetooth is not available on this device.';
        });
        return;
      }

      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        setState(() {
          hasError = true;
          errorMessage = 'Please turn on Bluetooth to use this app.';
        });
      } else {
        startScan();
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error initializing Bluetooth: ${e.toString()}';
      });
    }
  }

  void _setupAdapterListener() {
    adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        setState(() {
          hasError = false;
          errorMessage = '';
        });
        if (!isScanning && !isConnected) {
          startScan();
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Please turn on Bluetooth to use this app.';
          if (isConnected && selectedDevice != null) {
            disconnectFromDevice();
          }
        });
        stopScan();
      }
    });
  }

  // Start scanning for Bluetooth devices
  void startScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          setState(() {
            // Filter out devices with empty names
            scanResults = results.where((r) => r.device.name.isNotEmpty).toList();
          });
        },
        onError: (e) {
          setState(() {
            hasError = true;
            errorMessage = 'Scan error: ${e.toString()}';
            isScanning = false;
          });
        },
        onDone: () {
          setState(() {
            isScanning = false;
          });
        },
      );

      // Set a timer to stop scanning after timeout
      Future.delayed(const Duration(seconds: 15), () {
        stopScan();
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error starting scan: ${e.toString()}';
        isScanning = false;
      });
    }
  }

  // Stop scanning for Bluetooth devices
  void stopScan() {
    if (!isScanning) return;

    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
    setState(() {
      isScanning = false;
    });
  }

  // Connect to the selected Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
      hasError = false;
    });

    try {
      stopScan();

      // Set connection timeout
      bool connectionSuccess = false;

      await device
          .connect(timeout: const Duration(seconds: 10))
          .then((_) {
            connectionSuccess = true;
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timeout');
            },
          );

      if (connectionSuccess) {
        setState(() {
          selectedDevice = device;
          isConnected = true;
        });

        // Setup disconnection listener
        device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected && mounted) {
            setState(() {
              isConnected = false;
              selectedDevice = null;
              writeCharacteristic = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device disconnected')));
          }
        });

        // Discover services and characteristics
        List<BluetoothService> services = await device.discoverServices();
        bool foundWriteCharacteristic = false;

        for (var service in services) {
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              setState(() {
                writeCharacteristic = characteristic;
              });
              foundWriteCharacteristic = true;
              break;
            }
          }
          if (foundWriteCharacteristic) break;
        }

        if (!foundWriteCharacteristic) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find writable characteristic. Some features may not work.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected to ${device.name}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Connection error: ${e.toString()}';
          isConnected = false;
          selectedDevice = null;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() {
        isConnecting = false;
      });
    }
  }

  // Send data to the connected device
  Future<void> sendData(String data) async {
    if (writeCharacteristic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Write characteristic not found'), backgroundColor: Colors.red));
      return;
    }

    try {
      await writeCharacteristic!.write(utf8.encode(data));
      print('Data sent: $data');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending data: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  // Disconnect from the current device
  Future<void> disconnectFromDevice() async {
    if (selectedDevice != null) {
      try {
        await selectedDevice!.disconnect();
        if (mounted) {
          setState(() {
            isConnected = false;
            selectedDevice = null;
            writeCharacteristic = null;
          });
        }
      } catch (e) {
        print('Error disconnecting: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    stopScan();
    disconnectFromDevice();
    scanSubscription?.cancel();
    adapterStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Car', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: 'Controller', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          if (!isConnected)
            IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.refresh),
              onPressed: isScanning ? stopScan : startScan,
              tooltip: isScanning ? 'Stop scanning' : 'Start scanning',
            ),
        ],
      ),
      body:
          hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(errorMessage, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _checkPermissions, child: const Text('Retry')),
                  ],
                ),
              )
              : Column(
                children: <Widget>[
                  if (isConnecting) const LinearProgressIndicator(),
                  if (isScanning && !isConnected)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Scanning for devices...')]),
                    ),
                  isConnected && selectedDevice != null
                      ? ConnectedDeviceTile(
                        selectedDevice: selectedDevice,
                        disconnectFromDevice: disconnectFromDevice,
                        sendEmptyData: () => sendData('Z'),
                        sendForwardData: () => sendData('F'),
                        sendBackwardData: () => sendData('B'),
                        sendRightData: () => sendData('R'),
                        sendLeftData: () => sendData('L'),
                      )
                      : Expanded(
                        child:
                            scanResults.isEmpty && !isScanning
                                ? const Center(child: Text('No devices found. Pull to refresh.'))
                                : RefreshIndicator(
                                  onRefresh: () async {
                                    stopScan();
                                    startScan();
                                  },
                                  child: ListView.builder(
                                    itemCount: scanResults.length,
                                    itemBuilder: (context, index) {
                                      final result = scanResults[index];
                                      final device = result.device;

                                      return ListTile(
                                        title: Text(device.name),
                                        subtitle: Text('Signal: ${result.rssi} dBm | ID: ${device.id}'),
                                        leading: const Icon(Icons.bluetooth),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => connectToDevice(device),
                                      );
                                    },
                                  ),
                                ),
                      ),
                ],
              ),
    );
  }
}
