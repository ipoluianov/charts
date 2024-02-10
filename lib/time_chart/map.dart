import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as dart_ui;
import 'dart:ui';

import 'package:flutter/material.dart';

abstract class MapItem extends IPropContainer {
  late Map<String, String> props;
  double zoom = 1.0;
  List<MapItem> items = [];
  bool selected = false;
  bool isRoot = false;

  String lastBackImageBase64 = "";
  dart_ui.Image? backImage;

  String lastParentDataSource = "";

  MapItem() {
    props = {};
    backImage = null;
  }

  late String _id = "";

  @override
  String id() {
    return _id;
  }

  void generateAndSetNewId() {
    Random rnd = Random();
    var intRandom = rnd.nextInt(1000000);
    var dt = DateTime.now().microsecondsSinceEpoch;
    _id = dt.toString() + intRandom.toString();
  }

  double z(double value) {
    return value * zoom;
  }

  void tickItem() {
    tick();
  }

  void tick() {}

  Rect rect() {
    return Rect.fromLTWH(
        getDouble("x"), getDouble("y"), getDouble("w"), getDouble("h"));
  }

  Rect rectZ() {
    return Rect.fromLTWH(
        getDoubleZ("x"), getDoubleZ("y"), getDoubleZ("w"), getDoubleZ("h"));
  }

  Rect rectZWidthOffset(Offset offset) {
    return Rect.fromLTWH(getDoubleZ("x") + offset.dx,
        getDoubleZ("y") + offset.dy, getDoubleZ("w"), getDoubleZ("h"));
  }

  bool needToZoom() {
    return false;
  }

  void draw(Canvas canvas, Size size, List<String> parentMaps);

  double calcPrefScale() {
    return zoom;
  }

  @protected
  void resetToEndOfAnimation() {}

  @override
  void set(String name, String value) {
    props[name] = value;
  }

  @override
  String get(String name) {
    if (props.containsKey(name)) {
      if (props[name] == null) {
        return "";
      }
      return props[name]!;
    }
    return "";
  }

  @override
  void setDouble(String name, double value) {
    props[name] = value.toString();
  }

  double getDouble(String name) {
    var val = get(name);
    if (val != "") {
      double? res = double.tryParse(val);
      if (res != null) {
        return res;
      }
      return 0;
    }
    return 0;
  }

  TextAlign getTextAlign(String name) {
    TextAlign result = TextAlign.center;
    String val = get(name);
    if (val == "left") {
      result = TextAlign.left;
    }
    if (val == "center") {
      result = TextAlign.center;
    }
    if (val == "right") {
      result = TextAlign.right;
    }
    return result;
  }

  bool getBool(String name) {
    var val = get(name);
    return val == "1";
  }

  Color getColor(String name) {
    var val = get(name);
    if (val != "" && val[0] == "{") {
      return Colors.red;
    }
    if (val != "") {
      return Colors.deepOrange;
    }
    return Colors.transparent;
  }

  double getDoubleZ(String name) {
    var val = get(name);
    if (val != "") {
      double? res = double.tryParse(val);
      if (res != null) {
        return res * zoom;
      }
      return 0;
    }
    return 0;
  }

  @protected
  List<MapItemPropGroup> propGroupsOfItem() {
    List<MapItemPropGroup> groups = [];
    return groups;
  }

  String getDataSource() {
    var ds = get("data_source");
    if (ds.startsWith("~")) {
      if (lastParentDataSource.isNotEmpty) {
        ds = ds.replaceFirst("~", lastParentDataSource);
      }
    }
    return ds;
  }
}

class ActionPoint {
  String code;
  Rect rect;
  ActionPoint(this.code, this.rect);
}

class MapItemPropPage {
  String name;
  Icon icon;
  Widget? widget;
  List<MapItemPropGroup> groups;
  MapItemPropPage(this.name, this.icon, this.groups, {this.widget}) {
    widget = null;
  }
}

class MapItemPropGroup {
  String name;
  bool expanded;
  List<MapItemPropItem> props;
  MapItemPropGroup(this.name, this.expanded, this.props);
}

class MapItemPropItem {
  String name;
  String displayName;
  String type;
  String groupName;
  String defaultValue;
  MapItemPropItem(this.groupName, this.name, this.displayName, this.type,
      this.defaultValue);
}

abstract class IPropContainer {
  String id();
  void set(String name, String value);
  String get(String name);
  List<MapItemPropPage> propList();
  void setDouble(String name, double value);
}
