import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  static const tablet = 700.0;
  static const desktop = 1000.0;
  static const wide = 1280.0;
  static const maxContent = 1120.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isTablet => screenWidth >= Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;
}



double horizontalPaddingFor(
  double width, {
  double min = 16,
  double maxContent = Breakpoints.maxContent,
}) =>
    math.max(min, (width - maxContent) / 2);
