import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:sizer/sizer.dart';

class NavigationRailWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const NavigationRailWidget({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      useIndicator: false,
      indicatorShape: Border.all(width: 20),
      indicatorColor: Colors.transparent,
      //  minWidth: MediaQuery.of(context).size.width * 0.15,
      minWidth: 15.w,
      groupAlignment: 0,
      backgroundColor:
          const Color.fromARGB(255, 127, 127, 127).withOpacity(0.1),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationRailDestination(
                    icon: selectedIndex == 0
                        ? Icon(IconlyLight.home, color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.home, size: 9.w),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: selectedIndex == 1
                        ? Icon(IconlyLight.graph,
                            color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.graph, size: 9.w),
                    label: Text('Record'),
                  ),
                  NavigationRailDestination(
                    icon: selectedIndex == 2
                        ? Icon(IconlyLight.setting,
                            color: Colors.blue, size: 12.w)
                        : Icon(IconlyBroken.setting, size: 9.w),
                    label: Text('Settings'),
                  ),
      ],
    );
  }
}
