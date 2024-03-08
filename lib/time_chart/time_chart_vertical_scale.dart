import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as international;

import 'history.dart';

class TimeChartVerticalScale {
  static const double defaultVerticalScaleWidth = 0;
  static const double defaultVerticalScaleWidthInline = 50;

  TimeChartVerticalScale() {
    print("TimeChartVerticalScale()!!!!!!!!!!!!!!!!!!");
  }

  double xOffset = 0;
  double yOffset = 0;
  double width = 0;
  double height = 0;
  //double verticalScaleWidth = 0;

  double vmovingStartScale = 1;
  double vmovingStartDisplayedMin = 0;
  double vmovingStartDisplayedMax = 0;

  bool _fixedScale = false;
  void setFixedScale(bool value) {
    _fixedScale = value;
  }

  double signalOffset = 0;

  double verticalValuePadding01 = 0.2;

  double _displayedMinY = 0;
  double _displayedMaxY = 0;

  void setDisplayedMin(double min) {
    //print("setDisplayedMin $min");
    _displayedMinY = min;
  }

  void setDisplayedMax(double max) {
    _displayedMaxY = max;
  }

  double getDisplayedMinY() {
    return _displayedMinY;
  }

  double getDisplayedMaxY() {
    return _displayedMaxY;
  }

  void calc(double x, double y, double w, double h) {
    xOffset = x;
    yOffset = y;
    width = w;
    height = h;
  }

  void draw(Canvas canvas, Size size, Color color, int index, bool showLegend,
      int totalCount) {
    canvas.save();
    if (showLegend && totalCount > 1) {
      canvas.clipRect(Rect.fromLTWH(xOffset, (index + 1) * 22, width, height));
    }
    canvas.drawRect(
        Rect.fromLTWH(xOffset, 0, width, height),
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 1
          ..color = color.withOpacity(0.3));

    /*canvas.drawRect(
        Rect.fromLTWH(xOffset, 0, width, height),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color);*/

    var vertScalePointsCount = (height / 70).round();

    var verticalScale =
        getBeautifulScale(_displayedMinY, _displayedMaxY, vertScalePointsCount);
    for (var vertScaleItem in verticalScale) {
      var posY = verValueToPixel(vertScaleItem);
      if (posY.isNaN) {
        continue;
      }
      canvas.drawRect(
          Rect.fromLTWH(xOffset, posY - 8, width, 20),
          Paint()
            ..style = PaintingStyle.fill
            ..strokeWidth = 1
            ..color = Colors.black.withOpacity(0.5));

      drawText(canvas, xOffset, posY - 8, width - 5, 20,
          formatValue(vertScaleItem), 12, color, TextAlign.right);
      canvas.drawLine(
          Offset(xOffset + width - 3, posY),
          Offset(xOffset + width, posY),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color);

      canvas.drawLine(
          Offset(xOffset + width - 3, posY),
          Offset(xOffset + width + size.width, posY),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color.withOpacity(0.2));
    }

    /*canvas.drawLine(
        Offset(xOffset + width, 0),
        Offset(xOffset + width, height),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.redAccent);*/

    canvas.restore();
  }

  void updateVerticalScaleValues(List<Item> history, bool united) {
    if (_fixedScale) {
      return;
    }
    double displayedMinY = _displayedMinY;
    double displayedMaxY = _displayedMaxY;

    if (!united) {
      displayedMinY = double.maxFinite;
      displayedMaxY = -double.maxFinite;
    }
    for (int i = 0; i < history.length; i++) {
      var value = history[i];
      if (value.minValue < displayedMinY) {
        displayedMinY = value.minValue;
      }
      if (value.maxValue > displayedMaxY) {
        displayedMaxY = value.maxValue;
      }
    }
    if (displayedMinY != displayedMaxY) {
      displayedMinY = displayedMinY -
          (displayedMaxY - displayedMinY) * verticalValuePadding01;
      displayedMaxY = displayedMaxY +
          (displayedMaxY - displayedMinY) * verticalValuePadding01;
    } else {
      displayedMinY = displayedMinY - 1;
      displayedMaxY = displayedMaxY + 1;
    }

    setDisplayedMin(displayedMinY);
    setDisplayedMax(displayedMaxY);
  }

  void expandToZero() {
    if (_displayedMinY == double.maxFinite ||
        _displayedMaxY == -double.maxFinite) {
      return;
    }

    if (_displayedMinY > 0) {
      setDisplayedMin(0);
    }
    if (_displayedMaxY < 0) {
      setDisplayedMax(0);
    }
  }

  final f = international.NumberFormat("#.##########");
  String formatValue(num n) {
    return f.format(n);
  }

  List<double> getBeautifulScale(double min, double max, int countOfPoints) {
    List<double> scale = [];

    if (max < min) {
      return scale;
    }

    if (max == min) {
      scale.add(min);
      return scale;
    }

    var diapason = max - min;
    var step = diapason / countOfPoints;

    double log10(num x) => log(x) / ln10;
    var log1 = log10(step).roundToDouble();
    var step10 = pow(10, log1);

    while (diapason / step10 < countOfPoints) {
      step10 = step10 / 2;
    }

    for (var newMin = min - (min % step10); newMin < max; newMin += step10) {
      scale.add(newMin);
    }

    return scale;
  }

  void drawText(Canvas canvas, double x, double y, double width, double height,
      String text, double size, Color color, TextAlign align) {
    var textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        overflow: TextOverflow.fade,
      ),
    );
    final textPainter = TextPainter(
        text: textSpan, textDirection: TextDirection.ltr, textAlign: align);
    textPainter.layout(
      minWidth: width,
      maxWidth: width,
    );
    textPainter.paint(canvas, Offset(x, y));
  }

  double onePixelValue() {
    var diapason = _displayedMaxY - _displayedMinY;
    var onePixelValue = height / diapason;
    return onePixelValue;
  }

  double verValueToPixel(double value) {
    var diapason = _displayedMaxY - _displayedMinY;
    var offsetOfValueFromMin = value - _displayedMinY;
    var onePixelValue = height / diapason;
    return height - onePixelValue * offsetOfValueFromMin;
  }

  double verPixelToValue(double pixels) {
    var diapason = _displayedMaxY - _displayedMinY;
    var onePixelValue = height / diapason;
    return pixels / onePixelValue + _displayedMinY;
  }
}
