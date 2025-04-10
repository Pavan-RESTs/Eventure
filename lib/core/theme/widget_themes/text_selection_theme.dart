import 'package:flutter/material.dart';

class ITextSelectionTheme {
  ITextSelectionTheme._();

  static TextSelectionThemeData lightTextSelectionTheme =
      TextSelectionThemeData(
    cursorColor: Colors.black,
    selectionColor: Colors.yellow.withOpacity(0.3),
    selectionHandleColor: Colors.transparent,
  );

  static TextSelectionThemeData darkTextSelectionTheme = TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionColor: Colors.yellow.withOpacity(0.3),
    selectionHandleColor: Colors.transparent,
  );
}
