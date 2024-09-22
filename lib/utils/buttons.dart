import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  Button({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      child: Text(text),
      color: Color.fromRGBO(125, 106, 194, 2),
    );
  }
}
