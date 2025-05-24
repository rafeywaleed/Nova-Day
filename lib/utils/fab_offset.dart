import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CustomFABLocationWithSizer extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final double fabHeight = geometry.floatingActionButtonSize.height;

    // Use 10.h from the bottom
    final double bottomOffset = 11.h;

    final double bottom =
        geometry.scaffoldSize.height - bottomOffset - fabHeight;

    final double right = geometry.scaffoldSize.width -
        geometry.floatingActionButtonSize.width -
        16.0;

    return Offset(right, bottom);
  }
}
