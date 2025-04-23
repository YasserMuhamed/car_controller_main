import 'package:flutter/material.dart';

class ScanningIndicator extends StatelessWidget {
  const ScanningIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Scanning for devices...')]),
    );
  }
}
