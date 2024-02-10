import 'chart_group_item.dart';

class ChartGroup {
  late Map<String, String> props = {};
  List<ChartGroupItem> items = [];

  ChartGroup();

  void loadFromResource(String resourceId) {}

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    for (var propKey in props.keys) {
      result[propKey] = props[propKey];
    }

    List<Map<String, dynamic>> children = [];
    /*for (var ch in items) {
      var chRes = ch.toJson();
      children.add(chRes);
    }*/
    result["children"] = children;

    return result;
  }
}
