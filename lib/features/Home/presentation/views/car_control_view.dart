import 'package:flutter/material.dart';
import '../widgets/control_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:test_car_controller/features/Home/data/models/bluetooth_device_model.dart';
import 'package:test_car_controller/features/Home/presentation/manager/bluetooth/bluetooth_cubit.dart';

class CarControllerView extends StatelessWidget {
  final BluetoothDeviceModel deviceModel;

  const CarControllerView({super.key, required this.deviceModel});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BluetoothCubit, BluetoothState>(
      // Listen for state changes in the Cubit
      listener: (context, state) {
        // If the state indicates disconnection, navigate back
        if (state is BluetoothScanComplete || state is BluetoothError || state is BluetoothInitial) {
          // Check if we can pop (to avoid errors if we're already at the root)
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
           leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Disconnect and go back when back button is pressed
            context.read<BluetoothCubit>().disconnect();
            Navigator.of(context).pop();
          },
        ),
          centerTitle: true,
          title: const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Car', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: 'Controller', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.08, vertical: 16),
              child: ListTile(
                title: Text('Connected to ${deviceModel.name}'),
                trailing: MaterialButton(
                  onPressed: () {
                    context.read<BluetoothCubit>().disconnect();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Disconnect'),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Forward button
                    SizedBox(
                      width: (MediaQuery.of(context).size.width * 0.8) + 15,
                      height: 65,
                      child: ControlButton(
                        icon: FontAwesomeIcons.arrowUp,
                        onPressed: () {
                          context.read<BluetoothCubit>().sendForward();
                        },
                        onReleased: () {
                          context.read<BluetoothCubit>().sendStop();
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Left and right buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left button
                        Container(
                          margin: const EdgeInsets.only(right: 15),
                          height: 65,
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: ControlButton(
                            icon: FontAwesomeIcons.arrowLeft,
                            onPressed: () {
                              context.read<BluetoothCubit>().sendLeft();
                            },
                            onReleased: () {
                              context.read<BluetoothCubit>().sendStop();
                            },
                          ),
                        ),
                        // Right button
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 65,
                          child: ControlButton(
                            icon: FontAwesomeIcons.arrowRight,
                            onPressed: () {
                              context.read<BluetoothCubit>().sendRight();
                            },
                            onReleased: () {
                              context.read<BluetoothCubit>().sendStop();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Backward button
                    SizedBox(
                      width: (MediaQuery.of(context).size.width * 0.8) + 15,
                      height: 65,
                      child: ControlButton(
                        icon: FontAwesomeIcons.arrowDown,
                        onPressed: () {
                          context.read<BluetoothCubit>().sendBackward();
                        },
                        onReleased: () {
                          context.read<BluetoothCubit>().sendStop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
