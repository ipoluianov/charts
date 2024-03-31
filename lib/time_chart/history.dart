import 'dart:math';
import 'package:http/http.dart' as http;

class DataFile {
  //Map<String, String> files = {};
  Map<String, List<Item>> filesParsed = {};

  Future<void> fetchData(String url) async {
    try {
      print("fetchData $url");
      filesParsed[url] = [];
      http.get(Uri.parse(url)).then((value) {
        //print("OK-----------------");
        String v = value.body;
        //files[url] = v;
        filesParsed[url] = parseFile(v);
      }).catchError((e) {
        //files.remove(url);
        filesParsed.remove(url);
        print(e);
      });
    } catch (ex) {
      //files.remove(url);
      filesParsed.remove(url);
      print(ex);
    }
  }

  /*String getFile(String url) {
    //return "";
    if (files.containsKey(url)) {
      return files[url]!;
    }
    fetchData(url);
    return "";
  }*/

  List<Item> getFileData(String url) {
    //return "";
    if (filesParsed.containsKey(url)) {
      return filesParsed[url]!;
    }
    fetchData(url);
    return [];
  }

  List<Item> parseFile(String content) {
    List<Item> res = [];
    List<String> lines = content.split("\r\n");

    for (String line in lines) {
      List<String> parts = line.split("\t");
      if (parts.length < 5) {
        continue;
      }
      var dt = parts[0];
      var first = parts[1];
      var min = parts[2];
      var max = parts[3];
      var last = parts[4];

      double value = double.parse(first);
      int datetimeFirst = DateTime.parse(dt).microsecondsSinceEpoch;
      //int datetimeLast = datetimeFirst + groupTimeRange - 1;
      double firstValue = double.parse(first);
      double lastValue = double.parse(last);
      double minValue = double.parse(min);
      double maxValue = double.parse(max);
      double avgValue = value;
      double sumValue = value;
      int countOfValues = 1;
      List<int> qualities = [];
      bool hasGood = true;
      bool hasBad = false;
      String uom = "";

      Item item = Item(
        datetimeFirst,
        datetimeFirst,
        firstValue,
        lastValue,
        minValue,
        maxValue,
        avgValue,
        sumValue,
        countOfValues,
        qualities,
        hasGood,
        hasBad,
        uom,
      );
      item.tag = DateTime.fromMicrosecondsSinceEpoch(datetimeFirst).toString();
      res.add(item);
    }
    return res;
  }

  List<Item> getHistory(
      String itemName, int minTime, int maxTime, int groupTimeRange1) {
    //print(
    //    "getHistory ${DateTime.fromMicrosecondsSinceEpoch(minTime)} ${DateTime.fromMicrosecondsSinceEpoch(maxTime)}");
    List<Item> res = [];
    double value = 0.1;

    List<String> files = [];
    for (int t = minTime - 86400000000;
        t < maxTime + 86400000000;
        t += 86400 * 1000000) {
      DateTime dt = DateTime.fromMicrosecondsSinceEpoch(t);
      String yearStr = dt.year.toString();
      while (yearStr.length < 4) {
        yearStr = "0$yearStr";
      }
      int month = dt.month;
      String monthStr = month.toString();
      while (monthStr.length < 2) {
        monthStr = "0$monthStr";
      }
      String dayStr = dt.day.toString();
      while (dayStr.length < 2) {
        dayStr = "0$dayStr";
      }
      String fileName = "$yearStr-$monthStr-$dayStr.txt";
      var items = getFileData(itemName + "/$fileName");
      for (var item in items) {
        if (item.dtF >= minTime && item.dtL <= maxTime) {
          res.add(item);
        }
      }
    }

    if (res.isEmpty) {
      return res;
    }

    List<Item> result = [];

    int beginDT = res[0].dtF - res[0].dtF % groupTimeRange1;
    int resIndex = 0;

    for (int grDT = beginDT; grDT < maxTime; grDT += groupTimeRange1) {
      Item grItem = Item.makeDefault();
      grItem.dtF = grDT;
      grItem.dtL = grDT + groupTimeRange1 - 1;
      grItem.minValue = double.maxFinite;
      grItem.maxValue = -double.maxFinite;

      for (; resIndex < res.length; resIndex++) {
        Item item = res[resIndex];
        if (item.dtF >= grItem.dtF && item.dtL <= grItem.dtL) {
          if (item.minValue < grItem.minValue) grItem.minValue = item.minValue;
          if (item.maxValue > grItem.maxValue) grItem.maxValue = item.maxValue;
          if (grItem.countOfValues < 1) {
            grItem.firstValue = item.firstValue;
          }
          grItem.lastValue = item.lastValue;
          grItem.countOfValues++;
        } else {
          break;
        }
      }

      grItem.avgValue = (grItem.minValue + grItem.maxValue) / 2;

      result.add(grItem);
    }
    return result;
  }
}

class Item {
  int dtF;
  int dtL;
  double firstValue;
  double lastValue;
  double minValue;
  double maxValue;
  double avgValue;
  double sumValue;
  int countOfValues;
  List<int> qualities;
  bool hasGood;
  bool hasBad;
  String uom;
  String tag = "";

  Item(
      this.dtF,
      this.dtL,
      this.firstValue,
      this.lastValue,
      this.minValue,
      this.maxValue,
      this.avgValue,
      this.sumValue,
      this.countOfValues,
      this.qualities,
      this.hasGood,
      this.hasBad,
      this.uom);

  factory Item.makeDefault() {
    return Item(0, 0, 0, 0, 0, 0, 0, 0, 0, [], false, false, "");
  }

  factory Item.copy(Item item) {
    return Item(
        item.dtF,
        item.dtL,
        item.firstValue,
        item.lastValue,
        item.minValue,
        item.maxValue,
        item.avgValue,
        item.sumValue,
        item.countOfValues,
        item.qualities,
        item.hasGood,
        item.hasBad,
        "");
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      (double.tryParse("${json['tf']}") ?? 0).toInt(),
      (double.tryParse("${json['tl']}") ?? 0).toInt(),
      double.tryParse("${json['vf']}") ?? 0,
      double.tryParse("${json['vl']}") ?? 0,
      double.tryParse("${json['vd']}") ?? 0,
      double.tryParse("${json['vu']}") ?? 0,
      double.tryParse("${json['va']}") ?? 0,
      double.tryParse("${json['vs']}") ?? 0,
      json['c'],
      [],
      json['has_good'],
      json['has_bad'],
      json['uom'],
    );
  }
}
