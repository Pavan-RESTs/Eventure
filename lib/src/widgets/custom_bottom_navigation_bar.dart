import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = IDeviceUtils.getScreenWidth(context);
    bool isDark = IDeviceUtils.isDarkMode(context);

    return FlashyTabBar(
      backgroundColor: isDark ? IColors.dark : IColors.light,
      selectedIndex: currentIndex,
      showElevation: true,
      onItemSelected: onItemSelected,
      items: [
        FlashyTabBarItem(
          activeColor: IColors.primary,
          icon: Icon(
            Iconsax.calendar_search,
            color: IColors.primary,
            size: screenWidth * 0.07,
          ),
          title: Text(
            "Explore",
            style: TextStyle(
              color: isDark ? Colors.white70 : IColors.dark,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        FlashyTabBarItem(
          activeColor: IColors.primary,
          icon: Icon(
            Iconsax.calendar_edit,
            color: IColors.primary,
            size: screenWidth * 0.07,
          ),
          title: Text(
            "Modify",
            style: TextStyle(
              color: isDark ? Colors.white70 : IColors.dark,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        FlashyTabBarItem(
          activeColor: IColors.primary,
          icon: Icon(
            Iconsax.location,
            color: IColors.primary,
            size: screenWidth * 0.07,
          ),
          title: Text(
            "Venues",
            style: TextStyle(
              color: isDark ? Colors.white70 : IColors.dark,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
