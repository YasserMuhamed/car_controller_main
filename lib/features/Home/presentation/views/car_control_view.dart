import 'package:flutter/material.dart';
import '../widgets/control_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:garage_app/features/Home/data/models/bluetooth_device_model.dart';
import 'package:garage_app/features/Home/presentation/manager/bluetooth/bluetooth_cubit.dart';

class CarControllerView extends StatefulWidget {
  final BluetoothDeviceModel deviceModel;

  const CarControllerView({super.key, required this.deviceModel});

  @override
  State<CarControllerView> createState() => _CarControllerViewState();
}

class _CarControllerViewState extends State<CarControllerView> {
  bool mode = true; // Move mode to class level so it persists

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
                TextSpan(text: 'Garage', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: 'Controller', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            Switch.adaptive(
              activeColor: Colors.white,
              activeTrackColor: Colors.blue[700],
              value: mode,
              onChanged: (value) {
                if (value) {
                  setState(() {
                    mode = true;
                    context.read<BluetoothCubit>().sendManual();
                  });
                } else {
                  setState(() {
                    mode = false;
                    context.read<BluetoothCubit>().sendLineFollower();
                  });
                }
              },
            ),
          ],
        ),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.08, vertical: 16),
              child: ListTile(
                title: Text('Connected to ${widget.deviceModel.name}'),
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
                        icon: FontAwesomeIcons.squareParking,
                        buttonColor: Colors.grey,
                        pressedButtonColor: Colors.grey.shade800,
                        onPressed: () {
                          context.read<BluetoothCubit>().openUser();
                        },
                        onReleased: () {
                          context.read<BluetoothCubit>().sendStop();
                        },
                      ),
                    ),

                    const SizedBox(height: 45),
                    // Backward button
                    SizedBox(
                      width: (MediaQuery.of(context).size.width * 0.8) + 15,
                      height: 65,
                      child: ControlButton(
                        icon: FontAwesomeIcons.squareParking,
                        buttonColor: Colors.yellow.shade700,
                        pressedButtonColor: Colors.yellow.shade800,
                        onPressed: () {
                          context.read<BluetoothCubit>().openAdmin();
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
