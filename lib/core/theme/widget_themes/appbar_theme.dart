import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class IAppBarTheme {
  IAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: IColors.black, size: ISizes.iconMd),
    actionsIconTheme: IconThemeData(color: IColors.black, size: ISizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 24.0, fontWeight: FontWeight.w400, color: IColors.black),
  );
  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: IColors.black, size: ISizes.iconMd),
    actionsIconTheme: IconThemeData(color: IColors.white, size: ISizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 24.0, fontWeight: FontWeight.w400, color: IColors.white),
  );
}
