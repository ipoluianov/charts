import 'dart:ui';

import 'package:flutter/material.dart';

import '../chart_group_form/chart_group_data_items.dart';
import 'color_by_index.dart';
import '../history/history_loading_task.dart';
import 'history.dart';
import 'map.dart';
import 'time_chart_horizontal_scale.dart';
import 'time_chart_prop_container.dart';
import 'time_chart_settings.dart';
import 'time_chart_vertical_scale.dart';

class TimeChartSettingsSeries extends TimeChartPropContainer {
  double xOffset = 0;
  double yOffset = 0;
  double yOffsetOfHeader = 0;
  double width = 0;
  double height = 0;
  double verticalScaleWidth111 = 0;
  bool selected = false;
  String displayName = "";
  String chartType = "candles";

  TimeChartVerticalScale vScale = TimeChartVerticalScale();
  List<Item> itemHistory = [];
  List<HistoryLoadingTask> loadingTasks = [];

  TimeChartSettingsSeries(String itemName, this.itemHistory, Color color) {
    props = {};
    initDefaultProperties();
    set("item_name", itemName);
    set("stroke_color", colorToHex(color));
    generateAndSetNewId();
  }

  void calc(double x, double y, double w, double h, double vsWidth,
      TimeChartVerticalScale vSc, double yHeaderOffset) {
    //verticalScaleWidth = vsWidth;
    xOffset = x;
    yOffset = y;
    width = w;
    height = h;
    yOffsetOfHeader = yHeaderOffset;
    vScale = vSc;
  }

  void drawPoint(Item item) {}

  String itemName() {
    return get("item_name");
  }

  String getDisplayName() {
    if (displayName.isEmpty) {
      return itemName();
    }
    return displayName;
  }

  void drawClassic(
      Canvas canvas,
      Size s,
      TimeChartHorizontalScale hScale,
      TimeChartSettings settings,
      bool smooth,
      int index,
      int totalSeriesCount) {
    List<Item> history = itemHistory;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(xOffset + verticalScaleWidth111, 0,
        width - verticalScaleWidth111, height));

    {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = getColor("stroke_color")
        //..color = Colors.white
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      List<Offset> points = [];

      void funcDrawPoints() {
        if (points.length == 1) {
          canvas.drawCircle(points[0], 1, paint..style = PaintingStyle.fill);
        } else {
          if (smooth) {
            canvas.drawPoints(PointMode.polygon, points,
                paint..color = paint.color.withOpacity(0.2));
          } else {
            canvas.drawPoints(PointMode.polygon, points, paint);
          }
        }
        points = [];
      }

      //print("draw points: ${history.length}");

      for (int i = 0; i < history.length; i++) {
        var item = history[i];
        if (item.countOfValues > 0) {
          double posXdbl = hScale.horValueToPixel(item.dtF.toDouble());
          points.add(Offset(posXdbl, vScale.verValueToPixel(item.avgValue)));
        }
      }

      funcDrawPoints();
    }

    canvas.restore();
  }

  void drawCandles(
      Canvas canvas,
      Size s,
      TimeChartHorizontalScale hScale,
      TimeChartSettings settings,
      bool smooth,
      int index,
      int totalSeriesCount) {
    List<Item> history = itemHistory;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(xOffset + verticalScaleWidth111, 0,
        width - verticalScaleWidth111, height));

    {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = getColor("stroke_color")
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      var paintRectUp = Paint()
        ..style = PaintingStyle.fill
        ..color = getColor("stroke_color")
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      var paintRectDown = Paint()
        ..style = PaintingStyle.stroke
        ..color = getColor("stroke_color")
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      List<Offset> points = [];

      //print("draw points: ${history.length}");

      double timeRangeAvg = 0;
      for (int i = 0; i < history.length; i++) {
        timeRangeAvg += history[i].dtL - history[i].dtF;
      }
      timeRangeAvg = timeRangeAvg / history.length;
      double posX1 = hScale.horValueToPixel(0);
      double posX2 = hScale.horValueToPixel(timeRangeAvg);
      double pixelPerStick = posX2 - posX1;

      for (int i = 0; i < history.length; i++) {
        var item = history[i];
        double posXdbl = hScale.horValueToPixel(item.dtF.toDouble());

        points.add(Offset(posXdbl, vScale.verValueToPixel(item.minValue)));
        points.add(Offset(posXdbl, vScale.verValueToPixel(item.maxValue)));

        Paint paintRect = paintRectUp;
        if (item.lastValue < item.firstValue) {
          paintRect = paintRectDown;
        }
        canvas.drawRect(
            Rect.fromLTRB(
              posXdbl - pixelPerStick / 3,
              vScale.verValueToPixel(item.firstValue),
              posXdbl + pixelPerStick / 3,
              vScale.verValueToPixel(item.lastValue),
            ),
            paintRect);

        if (item.lastValue > item.firstValue) {
          canvas.drawLine(
              Offset(posXdbl, vScale.verValueToPixel(item.minValue)),
              Offset(posXdbl, vScale.verValueToPixel(item.firstValue)),
              paint);
          canvas.drawLine(
              Offset(posXdbl, vScale.verValueToPixel(item.maxValue)),
              Offset(posXdbl, vScale.verValueToPixel(item.lastValue)),
              paint);
        } else {
          canvas.drawLine(
              Offset(posXdbl, vScale.verValueToPixel(item.maxValue)),
              Offset(posXdbl, vScale.verValueToPixel(item.firstValue)),
              paint);
          canvas.drawLine(
              Offset(posXdbl, vScale.verValueToPixel(item.minValue)),
              Offset(posXdbl, vScale.verValueToPixel(item.lastValue)),
              paint);
        }
      }
    }

    canvas.restore();
  }

  void draw(
      Canvas canvas,
      Size s,
      TimeChartHorizontalScale hScale,
      TimeChartSettings settings,
      bool smooth,
      int index,
      int totalSeriesCount) {
    if (chartType == "candles") {
      drawCandles(canvas, s, hScale, settings, smooth, index, totalSeriesCount);
    }
    if (chartType == "lines") {
      drawClassic(canvas, s, hScale, settings, smooth, index, totalSeriesCount);
    }
  }

  void drawDetails(
      Canvas canvas,
      Size s,
      TimeChartHorizontalScale hScale,
      TimeChartSettings settings,
      bool smooth,
      int index,
      int totalSeriesCount) {
    List<Item> history = itemHistory;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(xOffset + verticalScaleWidth111, 0,
        width - verticalScaleWidth111, height));

    if (settings.selectionMin != settings.selectionMax) {
      Color color = getColor("stroke_color");

      double detailsWidth = 150;
      //double detailsHeight = 200;
      double detailsOffsetX =
          width - detailsWidth - (totalSeriesCount - index - 1) * detailsWidth;
      double detailsOffsetY = 0;
      double detailsItemHeight = 20;
      canvas.drawRect(
          Rect.fromLTWH(detailsOffsetX, 0, detailsWidth, height),
          Paint()
            ..color = Colors.black.withOpacity(0.6)
            ..style = PaintingStyle.fill);

      canvas.drawRect(
          Rect.fromLTWH(detailsOffsetX, 0, detailsWidth, height),
          Paint()
            ..color = color.withOpacity(0.2)
            ..style = PaintingStyle.fill);

      double statSum = 0;
      double statAVG = 0;
      double statMin = double.maxFinite;
      double statMax = -double.maxFinite;
      double statNum = 0;
      {
        for (int i = 0; i < history.length; i++) {
          var item = history[i];
          if (item.dtF > settings.selectionMin &&
              item.dtL < settings.selectionMax) {
              statNum += item.countOfValues;
              statSum += item.sumValue;
              if (item.minValue < statMin) {
                statMin = item.minValue;
              }
              if (item.maxValue > statMax) {
                statMax = item.maxValue;
              }
          }
        }

        if (statNum > 0) {
          statAVG = statSum / statNum;
        }
      }

      drawText(canvas, detailsOffsetX, detailsOffsetY, width, detailsItemHeight,
          "Min: $statMin", 12, color, TextAlign.start);
      detailsOffsetY += detailsItemHeight;

      drawText(canvas, detailsOffsetX, detailsOffsetY, width, detailsItemHeight,
          "Avg: $statAVG", 12, color, TextAlign.start);
      detailsOffsetY += detailsItemHeight;

      drawText(canvas, detailsOffsetX, detailsOffsetY, width, detailsItemHeight,
          "Max: $statMax", 12, color, TextAlign.start);
      detailsOffsetY += detailsItemHeight;

      /*drawText(canvas, detailsOffsetX, detailsOffsetY, width, detailsItemHeight, "Num: $statNum", 10, color, TextAlign.start);
      detailsOffsetY += detailsItemHeight;

      drawText(canvas, detailsOffsetX, detailsOffsetY, width, detailsItemHeight, "Sum: $statSum", 10, color, TextAlign.start);
      detailsOffsetY += detailsItemHeight;*/
    }

    canvas.restore();
  }

  String dataItem() {
    return get("item_name");
  }

  bool showZero() {
    return getBool("show_zero");
  }

  void drawText(Canvas canvas, double x, double y, double width, double height,
      String text, double size, Color color, TextAlign align) {
    var textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    for (var propKey in props.keys) {
      result[propKey] = props[propKey];
    }
    return result;
  }

  factory TimeChartSettingsSeries.fromJson(Map<String, dynamic> json) {
    var settings = TimeChartSettingsSeries(json['item_name'], [], Colors.amber);
    for (var propKey in json.keys) {
      settings.props[propKey] = json[propKey];
    }
    return settings;
  }

  @override
  List<MapItemPropPage> propList() {
    MapItemPropPage pageMain =
        MapItemPropPage("Series", const Icon(Icons.domain), []);
    MapItemPropPage pageDataItems =
        MapItemPropPage("Data Items", const Icon(Icons.data_usage), []);
    pageDataItems.widget = const ChartGroupDataItems();
    {
      List<MapItemPropItem> props = [];
      props.add(
          MapItemPropItem("", "stroke_color", "Color", "color", "FF00EFFF"));
      props.add(
          MapItemPropItem("", "stroke_width", "Stroke Width", "double", "1.5"));
      props.add(MapItemPropItem("", "show_zero", "Show Zero", "bool", "0"));
      pageMain.groups.add(MapItemPropGroup("View", true, props));
    }
    {
      List<MapItemPropItem> props = [];
      props.add(
          MapItemPropItem("", "item_name", "Data Source", "data_source", ""));
      pageMain.groups.add(MapItemPropGroup("Data Source", true, props));
    }
    return [pageMain, pageDataItems];
  }
}
