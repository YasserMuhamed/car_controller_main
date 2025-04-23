import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:test_car_controller/hold_button.dart';


class ConnectedDeviceTile extends StatelessWidget {
  const ConnectedDeviceTile({
    super.key,
    this.selectedDevice,
    required this.disconnectFromDevice,
    required this.sendForwardData,
    required this.sendBackwardData,
    required this.sendRightData,
    required this.sendLeftData,
    required this.sendEmptyData,
  });
  final BluetoothDevice? selectedDevice;
  final VoidCallback disconnectFromDevice;
  final VoidCallback sendForwardData;
  final VoidCallback sendBackwardData;
  final VoidCallback sendRightData;
  final VoidCallback sendLeftData;
  final VoidCallback sendEmptyData;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * .08),
          child: SizedBox.fromSize(
            child: ListTile(
              title: Text('Connected to ${selectedDevice!.name}'),
              trailing: ElevatedButton(
                onPressed: disconnectFromDevice,
                child: const Text('Disconnect'),
              ),
            ),
          ),
        ),
        // Text input to send data to the Bluetooth device
        Container(
          margin: const EdgeInsets.symmetric(vertical: 15),
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width * .8) + 15,
                  height: 65,
                  child: HoldButton(
                    icon: const Icon(FontAwesomeIcons.arrowUp,
                        color: Colors.white),
                    onHoldDown: () {
                      sendForwardData();
                    },
                    onHoldUp: () {
                      sendEmptyData();
                    },
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 15),
                      height: 65,
                      width: MediaQuery.sizeOf(context).width * .4,
                      child: HoldButton(
                        icon: const Icon(FontAwesomeIcons.arrowLeft,
                            color: Colors.white),
                        onHoldDown: () {
                          sendLeftData();
                        },
                        onHoldUp: () {
                          sendEmptyData();
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * .4,
                      height: 65,
                      child: HoldButton(
                        icon: const Icon(FontAwesomeIcons.arrowRight,
                            color: Colors.white),
                        onHoldDown: () {
                          sendRightData();
                        },
                        onHoldUp: () {
                          sendEmptyData();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width * .8) + 15,
                  height: 65,
                  child: HoldButton(
                    icon: const Icon(FontAwesomeIcons.arrowDown,
                        color: Colors.white),
                    onHoldDown: () {
                      sendBackwardData();
                    },
                    onHoldUp: () {
                      sendEmptyData();
                    },
                  ),
                ),
              ])),
        ),
      ]),
    );
  }
}
