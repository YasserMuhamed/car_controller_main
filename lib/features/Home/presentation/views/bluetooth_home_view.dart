import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_car_controller/core/utils/helpers.dart';
import 'package:test_car_controller/features/Home/presentation/views/error_view.dart';
import 'package:test_car_controller/features/Home/presentation/views/car_control_view.dart';
import 'package:test_car_controller/features/Home/presentation/widgets/device_list_item.dart';
import 'package:test_car_controller/features/Home/presentation/widgets/scanning_indicator.dart';
import 'package:test_car_controller/features/Home/presentation/manager/bluetooth/bluetooth_cubit.dart';


class BluetoothHomeView extends StatelessWidget {
  const BluetoothHomeView({super.key});

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
          BlocBuilder<BluetoothCubit, BluetoothState>(
            builder: (context, state) {
              if (state is BluetoothConnected) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: Icon(state is BluetoothScanning ? Icons.stop : Icons.refresh),
                onPressed: () {
                  if (state is BluetoothScanning) {
                    context.read<BluetoothCubit>().stopScan();
                  } else {
                    context.read<BluetoothCubit>().startScan();
                  }
                },
                tooltip: state is BluetoothScanning ? 'Stop scanning' : 'Start scanning',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BluetoothCubit, BluetoothState>(
        listener: (context, state) {
          if (state is BluetoothError) {
            Helpers.showErrorSnackBar(context, state.message);
          } else if (state is BluetoothConnected) {
            Helpers.showSuccessSnackBar(context, 'Connected to ${state.deviceModel.name}');
             Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider.value(
                      value: BlocProvider.of<BluetoothCubit>(context), // Pass the existing Cubit instance
                      child: CarControllerView(deviceModel: state.deviceModel),
                    ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BluetoothInitial || state is BluetoothLoading || state is BluetoothConnecting ) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BluetoothError) {
            return ErrorView(errorMessage: state.message, onRetry: () => context.read<BluetoothCubit>().initialize());
          } else {
            final isScanning = state is BluetoothScanning;
            final devices =
                state is BluetoothScanning
                    ? state.devices
                    : state is BluetoothScanComplete
                    ? state.devices
                    : [];

            return Column(
              children: [
                if (isScanning) const ScanningIndicator(),
                Expanded(
                  child:
                      devices.isEmpty && !isScanning
                          ? RefreshIndicator(
                            onRefresh: ()async {
                               context.read<BluetoothCubit>().startScan();
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                const Center(child: Text('No devices found. Pull to refresh.')),
                                ],
                              ),
                              ),
                            ),
                            )
                          : RefreshIndicator(
                            onRefresh: () async {
                              context.read<BluetoothCubit>().startScan();
                            },
                            child: ListView.builder(
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                final device = devices[index];
                                return DeviceListItem(
                                  device: device,
                                  onTap: () {
                                    context.read<BluetoothCubit>().connectToDevice(device);
                                  },
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
