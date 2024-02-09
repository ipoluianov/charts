class DataFile {
  List<DataItemHistoryChartItemValueResponse> getHistory(
      String itemName, int minTime, int maxTime, int groupTimeRange) {
    List<DataItemHistoryChartItemValueResponse> res = [];
    return res;
  }
}

class DataItemHistoryChartItemValueResponse {
  int datetimeFirst;
  int datetimeLast;
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

  DataItemHistoryChartItemValueResponse(
      this.datetimeFirst,
      this.datetimeLast,
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

  factory DataItemHistoryChartItemValueResponse.fromJson(
      Map<String, dynamic> json) {
    return DataItemHistoryChartItemValueResponse(
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
