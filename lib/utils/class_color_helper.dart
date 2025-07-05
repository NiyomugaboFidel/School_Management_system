import 'package:flutter/material.dart';

class ClassColorHelper {
  static const List<Color> _classColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.pink,
    Colors.cyan,
  ];

  static Color getColorForClass(int classId) {
    return _classColors[classId % _classColors.length];
  }
}
