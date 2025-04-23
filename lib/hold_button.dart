import 'package:flutter/material.dart';
import 'dart:async'; // To handle the Timer.

class HoldButton extends StatefulWidget {
  final VoidCallback onHoldDown;
  final VoidCallback onHoldUp;
  final Icon icon;

  const HoldButton(
      {required this.onHoldDown,
      required this.onHoldUp,
      super.key,
      required this.icon});

  @override
  _HoldButtonState createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _isHolding = false;
  Timer? _holdTimer;

  void _handleHoldStart() {
    if (!_isHolding) {
      setState(() {
        _isHolding = true;
      });
      widget.onHoldDown(); // Trigger the onHoldDown callback
      _startHoldTimer();
    }
  }

  void _handleHoldEnd() {
    if (_isHolding) {
      setState(() {
        _isHolding = false;
      });
      widget.onHoldUp(); // Trigger the onHoldUp callback
      _holdTimer?.cancel();
    }
  }

  void _startHoldTimer() {
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isHolding) {
        widget.onHoldDown(); // Keep triggering onHoldDown if the button is held
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleHoldStart(),
      onTapUp: (_) => _handleHoldEnd(),
      onTapCancel: _handleHoldEnd,
      child: Container(
        width: 200,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHolding ? Colors.blueGrey : Colors.blue[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.icon,
      ),
    );
  }
}
