import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AnimateDoIconSwitcher extends StatefulWidget {
  final List<IconData> icons;
  final Duration switchDuration;
  final double size;
  final Color color;

  const AnimateDoIconSwitcher({
    Key? key,
    required this.icons, // Pass a list of 4 icons
    this.switchDuration = const Duration(seconds: 3),
    this.size = 24.0,
    this.color = Colors.black54,
  })  : assert(icons.length == 4, 'Exactly 4 icons required'),
        super(key: key);

  @override
  _AnimateDoIconSwitcherState createState() => _AnimateDoIconSwitcherState();
}

class _AnimateDoIconSwitcherState extends State<AnimateDoIconSwitcher> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.switchDuration, (_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.icons.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlipInY(
      key: ValueKey(_currentIndex),
      duration: const Duration(milliseconds: 1000),
      child: Icon(
        widget.icons[_currentIndex],
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
