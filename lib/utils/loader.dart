import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PLoader extends StatelessWidget {
  const PLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center( // Center the loader in the available space
      child: Transform.scale(
        scale: 2, // Use a reasonable scale factor
        child: const CircularProgressIndicator(
          strokeWidth:7,
          backgroundColor: Color.fromARGB(255, 123, 123, 123),
          valueColor: AlwaysStoppedAnimation(Colors.blue),
        ),
      ),
    );
  }
}
