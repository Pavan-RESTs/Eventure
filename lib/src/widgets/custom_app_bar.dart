import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/src/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.isDark,
    required this.onRefreshPressed,
  });

  final bool isDark;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: isDark ? IColors.dark : IColors.light,
        elevation: 0,
        scrolledUnderElevation: 2.0,
        shadowColor: isDark
            ? Colors.black.withOpacity(0.3)
            : IColors.primary.withOpacity(0.1),
        titleSpacing: 0,
        leadingWidth: 60,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(
              Iconsax.refresh_circle,
              color: IColors.primary,
            ),
            onPressed: onRefreshPressed,
          ),
        ),
        title: Text(
          "    Event Management",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? IColors.textWhite : IColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Iconsax.filter,
              color: IColors.primary,
            ),
            onPressed: () {
              // Handle filter action
            },
          ),
          IconButton(
            icon: const Icon(
              Iconsax.logout,
              color: IColors.primary,
              size: 25,
            ),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Get.offAll(LoginScreen());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
