import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:garage_app/core/app_constants.dart';
import 'package:garage_app/features/Home/data/models/bluetooth_device_model.dart';
import 'package:garage_app/features/Home/data/repository/bluetooth_repo.dart';

part 'bluetooth_state.dart';

class BluetoothCubit extends Cubit<BluetoothState> {
  final BluetoothRepository _repository;

  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _connectionStateSubscription;

  BluetoothCubit({required BluetoothRepository repository}) : _repository = repository, super(BluetoothInitial());

  Future<void> initialize() async {
    emit(BluetoothLoading());

    final hasPermissions = await _repository.checkPermissions();
    if (!hasPermissions) {
      emit(const BluetoothError('Bluetooth permissions denied. Please enable them in settings.'));
      return;
    }

    final isAvailable = await _repository.isBluetoothAvailable();
    if (!isAvailable) {
      emit(const BluetoothError('Bluetooth is not available on this device.'));
      return;
    }

    final adapterState = await _repository.getBluetoothState();
    if (adapterState != BluetoothAdapterState.on) {
      emit(const BluetoothError('Please turn on Bluetooth to use this app.'));
      return;
    }

    _setupAdapterStateListener();
    startScan();
  }

  void _setupAdapterStateListener() {
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = _repository.getBluetoothStateStream().listen((state) {
      if (state == BluetoothAdapterState.on) {
        if (this.state is BluetoothError) {
          startScan();
        }
      } else {
        if (_repository.connectedDevice != null) {
          disconnect();
        }
        stopScan();
        emit(const BluetoothError('Please turn on Bluetooth to use this app.'));
      }
    });
  }

  Future<void> startScan() async {
    if (state is BluetoothScanning) return;

    emit(BluetoothScanning(devices: []));

    try {
      await _repository.startScan();

      _scanResultsSubscription?.cancel();
      _scanResultsSubscription = _repository.getScanResults().listen(
        (devices) {
          emit(BluetoothScanning(devices: devices));
        },
        onError: (error) {
          emit(BluetoothError(error.toString()));
        },
      );

      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (state is BluetoothScanning) {
          stopScan();
        }
      });
    } catch (e) {
      emit(BluetoothError('Error starting scan: $e'));
    }
  }

  void stopScan() {
    if (state is! BluetoothScanning) return;

    _repository.stopScan();
    _scanResultsSubscription?.cancel();

    if (state is BluetoothScanning) {
      final devices = (state as BluetoothScanning).devices;
      emit(BluetoothScanComplete(devices: devices));
    }
  }

  Future<void> connectToDevice(BluetoothDeviceModel deviceModel) async {
    emit(BluetoothConnecting());

    try {
      await _repository.stopScan();
      _scanResultsSubscription?.cancel();

      final success = await _repository.connectToDevice(deviceModel.device);

      if (success) {
        _setupConnectionStateListener();
        emit(BluetoothConnected(deviceModel: deviceModel));
      } else {
        emit(const BluetoothError('Could not find writable characteristic'));
      }
    } catch (e) {
      emit(BluetoothError('Connection error: $e'));
    }
  }

  void _setupConnectionStateListener() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _repository.getConnectionState()?.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        emit(BluetoothScanComplete(devices: const []));
      }
    });
  }

  Future<void> sendCommand(String command) async {
    if (state is! BluetoothConnected) return;

    final success = await _repository.sendCommand(command);
    if (!success) {
      print('Failed to send command: $command');
      emit(const BluetoothError('Failed to send command'));
      await Future.delayed(const Duration(seconds: 1));

      if (_repository.connectedDevice != null) {
        emit(BluetoothConnected(deviceModel: BluetoothDeviceModel(device: _repository.connectedDevice!, rssi: 0)));
      } else {
        emit(BluetoothScanComplete(devices: const []));
      }
    }
  }

  Future<void> openUser() async {
    await sendCommand(AppConstants.COMMAND_USER);
  }

  Future<void> openAdmin() async {
    await sendCommand(AppConstants.COMMAND_ADMIN);
  }

  Future<void> sendStop() async {
    await sendCommand(AppConstants.COMMAND_STOP);
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    _connectionStateSubscription?.cancel();
    emit(BluetoothScanComplete(devices: const []));
  }

  @override
  Future<void> close() {
    _scanResultsSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
