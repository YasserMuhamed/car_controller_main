part of 'bluetooth_cubit.dart';

abstract class BluetoothState extends Equatable {
  const BluetoothState();

  @override
  List<Object?> get props => [];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothLoading extends BluetoothState {}

class BluetoothError extends BluetoothState {
  final String message;

  const BluetoothError(this.message);

  @override
  List<Object?> get props => [message];
}

class BluetoothScanning extends BluetoothState {
  final List<BluetoothDeviceModel> devices;

  const BluetoothScanning({required this.devices});

  @override
  List<Object?> get props => [devices];
}

class BluetoothScanComplete extends BluetoothState {
  final List<BluetoothDeviceModel> devices;

  const BluetoothScanComplete({required this.devices});

  @override
  List<Object?> get props => [devices];
}

class BluetoothConnecting extends BluetoothState {}

class BluetoothConnected extends BluetoothState {
  final BluetoothDeviceModel deviceModel;

  const BluetoothConnected({required this.deviceModel});

  @override
  List<Object?> get props => [deviceModel];
}
