import 'package:flutter/material.dart';

Color colorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}

String colorToHex(Color col) => '${col.alpha.toRadixString(16).padLeft(2, '0')}'
    '${col.red.toRadixString(16).padLeft(2, '0')}'
    '${col.green.toRadixString(16).padLeft(2, '0')}'
    '${col.blue.toRadixString(16).padLeft(2, '0')}';

Color colorByIndex(int index) {
  Color result = Colors.white;
  switch (index % 4) {
    case 0:
      result = colorFromHex("#00ABC5");
      break;
    case 1:
      result = colorFromHex("#F7941D");
      break;
    case 2:
      result = colorFromHex("#6EC05C");
      break;
    case 3:
      result = colorFromHex("#EF4C45");
      break;
  }
  return result;
}
