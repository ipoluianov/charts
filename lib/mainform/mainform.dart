import 'package:charts/time_chart/time_chart.dart';
import 'package:charts/time_chart/time_chart_settings_area.dart';
import 'package:flutter/material.dart';

import '../time_chart/color_by_index.dart';
import '../time_chart/time_chart_settings.dart';
import '../time_chart/time_chart_settings_series.dart';

class MainForm extends StatefulWidget {
  const MainForm({super.key});

  @override
  State<StatefulWidget> createState() {
    return MainFormState();
  }
}

class MainFormState extends State<MainForm> {
  TimeChartSettings _settings = TimeChartSettings([]);
  @override
  void initState() {
    super.initState();
    _settings.areas = [
      TimeChartSettingsArea([]),
      //TimeChartSettingsArea([]),
    ];

    _settings.areas[0].series.add(TimeChartSettingsSeries(
        "https://test.u00.io:8401/bybit/BTCUSDT",
        [],
        colorByIndex(_settings.areas[0].series.length)));
    _settings.areas[0].set("united_scale", "0");
  }

  Widget buildContent(BuildContext context) {
    return TimeChart("qqq", _settings, () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildContent(context),
    );
  }
}
