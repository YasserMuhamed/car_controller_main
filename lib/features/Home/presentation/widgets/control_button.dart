import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const ControlButton({super.key, required this.icon, required this.onPressed, required this.onReleased});

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onReleased();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        widget.onReleased();
      },
      child: Container(
        decoration: BoxDecoration(color: _isPressed ? Colors.blue.shade800 : Colors.blue, borderRadius: BorderRadius.circular(10)),
        child: Center(child: FaIcon(widget.icon, color: Colors.white, size: 24)),
      ),
    );
  }
}
