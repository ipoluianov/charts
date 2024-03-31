import 'dart:async';

import 'package:charts/instruments_list/instruments_list_dialog.dart';
import 'package:charts/time_chart/time_chart_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'history.dart';
import 'time_chart_painter.dart';

class TimeChart extends StatefulWidget {
  final String itemName;
  final TimeChartSettings _settings;
  final Function onChanged;
  const TimeChart(this.itemName, this._settings, this.onChanged, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TimeChartState();
  }
}

class TimeChartState extends State<TimeChart> with TickerProviderStateMixin {
  late Timer _timerUpdateTimeRange =
      Timer.periodic(const Duration(milliseconds: 1000), (timer) {});

  final DataFile _dataFile = DataFile();

  String chartType = "candles";
  int groupTimeSec = 3600;

  @override
  void initState() {
    requestHistory();
    setUpdateTimePeriodMs(100);
    loadDefaultTimeRange();
    super.initState();
  }

  void requestHistory() {
    return;
  }

  void setUpdateTimePeriodMs(int durationMs) {
    _timerUpdateTimeRange.cancel();
    _timerUpdateTimeRange =
        Timer.periodic(Duration(milliseconds: durationMs), (t) {
      updateTimes();
    });
  }

  void setDisplayRange(double min, double max) {
    widget._settings.horScale.setDefaultDisplayRange(min, max);
  }

  void loadDefaultTimeRange() {
    setDisplayRange(DateTime(2024, 3, 1).microsecondsSinceEpoch.toDouble(),
        DateTime(2024, 3, 31).microsecondsSinceEpoch.toDouble());
  }

  int calcTimeRange(int timePerPixelSec) {
    int result = 1;
    if (timePerPixelSec >= 1 && timePerPixelSec <= 59) {
      result = 60;
    }
    if (timePerPixelSec >= 60 && timePerPixelSec <= 299) {
      result = 300;
    }
    if (timePerPixelSec >= 300 && timePerPixelSec <= 599) {
      result = 600;
    }
    if (timePerPixelSec >= 600 && timePerPixelSec <= 899) {
      result = 900;
    }
    if (timePerPixelSec >= 900 && timePerPixelSec <= 1799) {
      result = 1800;
    }
    if (timePerPixelSec >= 1800 && timePerPixelSec <= 3599) {
      result = 3600;
    }
    if (timePerPixelSec >= 3600 && timePerPixelSec <= 10799) {
      result = 10800;
    }
    if (timePerPixelSec >= 10800 && timePerPixelSec <= 21599) {
      result = 21600;
    }
    if (timePerPixelSec >= 21600) {
      result = 86400;
    }
    return result;
  }

  String nameForTimeRange(int timeRange) {
    String result = "1";
    switch (timeRange) {
      case 1:
        result = "1";
        break;
      case 60:
        result = "1 min";
        break;
      case 300:
        result = "5 min";
        break;
      case 600:
        result = "10 min";
        break;
      case 900:
        result = "15 min";
        break;
      case 1800:
        result = "30 min";
        break;
      case 3600:
        result = "1 hour";
        break;
      case 10800:
        result = "3 hours";
        break;
      case 21600:
        result = "6 hours";
        break;
      case 43200:
        result = "12 hours";
        break;
      case 86400:
        result = "24 hours";
        break;
    }
    return result;
  }

  void smoothingItemsAvg(List<Item> items) {
    int kernel = 5;
    for (int i = 0; i < items.length; i++) {
      double v = 0;
      int count = 0;
      for (int k = i - kernel; k < i + kernel; k++) {
        if (i > 0 && i < items.length) {
          v += items[i].avgValue;
          count++;
        }
      }
      if (count > 0) {
        v = v / count;
      }
      items[i].avgValue = v;
    }
  }

  double calcMin(List<Item> items) {
    double min = double.maxFinite;
    for (var item in items) {
      if (item.minValue < min) {
        min = item.minValue;
      }
    }
    return min;
  }

  double calcMax(List<Item> items) {
    double max = -double.maxFinite;
    for (var item in items) {
      if (item.maxValue > max) {
        max = item.maxValue;
      }
    }
    return max;
  }

  void markSilence(List<Item> items) {
    double min = calcMin(items);
    double max = calcMax(items);
    double range = max - min;
    widget._settings.markers = [];
    int count = 0;
    int begin = 0;
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      double treshold = 0.03;
      if (item.maxValue - item.minValue > range * treshold) {
        if (begin < 1) {
          begin = item.dtF;
        }
        count++;
      } else {
        if (begin > 0 && count > 100) {
          widget._settings.markers.add(
            Offset(begin.toDouble(), item.dtF.toDouble()),
          );
          begin = 0;
        }
      }
    }
    //print(widget._settings.markers.length);
    return;
  }

  void updateTimes() {
    setState(() {
      double w = widget._settings.horScale.width;
      if (w < 1) {
        return;
      }

      double r = widget._settings.horScale.displayMax -
          widget._settings.horScale.displayMin;
      int timePerStick = (r / w).round();
      if (chartType == "candles") {
        timePerStick = (timePerStick * 7).round();
      }

      widget._settings.verticalLines = [];
      for (double t = widget._settings.horScale.displayMin -
              (widget._settings.horScale.displayMin % 86400000000);
          t < widget._settings.horScale.displayMax;
          t += 86400 * 1000000) {
        widget._settings.verticalLines.add(t);
      }

      //print("time per pixel1 ${timePerPixel / 1000000}");
      timePerStick = calcTimeRange((timePerStick / 1000000).round()) * 1000000;

      print("timePerStick ${timePerStick / 1000000}");

      for (int areaIndex = 0;
          areaIndex < widget._settings.areas.length;
          areaIndex++) {
        var area = widget._settings.areas[areaIndex];
        for (int seriesIndex = 0;
            seriesIndex < area.series.length;
            seriesIndex++) {
          var series = area.series[seriesIndex];
          var data = _dataFile.getHistory(
              series.itemName(),
              widget._settings.horScale.displayMin.round(),
              widget._settings.horScale.displayMax.round(),
              groupTimeSec * 1000000);

          // markSilence(data);

          //smoothingItemsAvg(data);

          if (areaIndex == 0) {
            double min = double.maxFinite;
            double max = 0;

            for (var item in data) {
              if (item.minValue < min) {
                min = item.minValue;
              }
              if (item.maxValue > max) {
                max = item.maxValue;
              }
            }

            //widget._settings.markers = [];

            int detectedUpTime = 0;
            int detectedUpCount = 0;
            double detectedUpLastValue = 0;
            for (var item in data) {
              if (item.avgValue > detectedUpLastValue) {
                if (detectedUpTime < 1) {
                  detectedUpTime = item.dtF;
                }
                detectedUpCount++;
              } else {
                if (detectedUpTime > 0 && detectedUpCount > 3) {
                  /*widget._settings.markers.add(
                    Offset(detectedUpTime.toDouble(), item.dtF.toDouble()),
                  );*/
                }
                detectedUpTime = 0;
                detectedUpCount = 0;
              }
              detectedUpLastValue = item.avgValue;
            }
          }

          series.displayName =
              "${series.itemName()} ${nameForTimeRange((groupTimeSec).floor())}";

          if (data.isNotEmpty) {
            series.itemHistory = data;
          }
          series.chartType = chartType;
        }
      }
    });
  }

  @override
  void dispose() {
    _timerUpdateTimeRange.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Widget buildTimeFilterButtons(context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> buttons = [
          OutlinedButton(
              onPressed: () {
                double min = widget._settings.horScale.displayMin;
                double max = widget._settings.horScale.displayMax;
                double timeRange = max - min;
                widget._settings.horScale
                    .setDisplayRange(min - timeRange / 2, max + timeRange / 2);
              },
              child: Text("-")),
          OutlinedButton(
              onPressed: () {
                double min = widget._settings.horScale.displayMin;
                double max = widget._settings.horScale.displayMax;
                double timeRange = max - min;
                widget._settings.horScale.setDisplayRange(
                    min + timeRange * 0.1, max - timeRange * 0.1);
              },
              child: Text("+")),
          OutlinedButton(
              onPressed: () {
                for (var area in widget._settings.areas) {
                  for (var ser in area.series) {
                    ser.vScale.setFixedScale(false);
                  }
                }
              },
              child: Text("vReset")),
          OutlinedButton(
              onPressed: () {
                showInstrumentsListDialog(context).then((value) {
                  print("OK---- $value");
                });
              },
              child: Text("Add")),
          OutlinedButton(
              onPressed: () {
                chartType = "candles";
              },
              child: Text(
                "Candles",
                style: TextStyle(
                  color: chartType == "candles" ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
            onPressed: () {
              chartType = "lines";
            },
            child: Text(
              "Lines",
              style: TextStyle(
                color: chartType == "lines" ? Colors.yellow : Colors.blue,
              ),
            ),
          ),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 60;
              },
              child: Text(
                "1 min",
                style: TextStyle(
                  color: groupTimeSec == 60 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 300;
              },
              child: Text(
                "5 min",
                style: TextStyle(
                  color: groupTimeSec == 300 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 600;
              },
              child: Text(
                "10 min",
                style: TextStyle(
                  color: groupTimeSec == 600 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 900;
              },
              child: Text(
                "15 min",
                style: TextStyle(
                  color: groupTimeSec == 900 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 3600;
              },
              child: Text(
                "1 hour",
                style: TextStyle(
                  color: groupTimeSec == 3600 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 10800;
              },
              child: Text(
                "3 hours",
                style: TextStyle(
                  color: groupTimeSec == 10800 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 21600;
              },
              child: Text(
                "6 hours",
                style: TextStyle(
                  color: groupTimeSec == 21600 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 43200;
              },
              child: Text(
                "12 hours",
                style: TextStyle(
                  color: groupTimeSec == 43200 ? Colors.yellow : Colors.blue,
                ),
              )),
          OutlinedButton(
              onPressed: () {
                groupTimeSec = 86400;
              },
              child: Text(
                "24 hours",
                style: TextStyle(
                  color: groupTimeSec == 86400 ? Colors.yellow : Colors.blue,
                ),
              )),
        ];

        return Row(
          children: buttons,
        );
      },
    );
  }

  Widget buildTimeFilter(context) {
    return Container(
      padding: const EdgeInsets.only(left: 3),
      //height: 36,
      child: Row(
        children: [
          Expanded(child: buildTimeFilterButtons(context)),
        ],
      ),
    );
  }

  final FocusNode _focusNode = FocusNode();

  bool keyControl = false;
  bool keyShift = false;
  bool keyAlt = false;

  RenderBox? lastRenderBox_;

  MouseCursor chartCursor() {
    return widget._settings.mouseCursor();
  }

  String acceptedData = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildTimeFilter(context),
        Expanded(
          child: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: (ev) {
              setState(() {
                keyControl = ev.isControlPressed;
                keyAlt = ev.isAltPressed;
                keyShift = ev.isShiftPressed;
                widget._settings.setKeys(keyControl, keyAlt, keyShift);
              });
              //print("key: ${keyControl}");
            },
            child: MouseRegion(
              cursor: chartCursor(),
              onEnter: (ev) {
                setState(() {
                  widget._settings.onEnter(ev);
                });
              },
              onExit: (ev) {
                setState(() {
                  widget._settings.onLeave(ev);
                });
              },
              child: Listener(
                onPointerDown: (PointerDownEvent ev) {
                  FocusScope.of(context).requestFocus(_focusNode);
                  widget.onChanged();
                },
                onPointerMove: (PointerMoveEvent ev) {},
                onPointerUp: (PointerUpEvent ev) {
                  setState(() {});
                  widget.onChanged();
                },
                onPointerSignal: (pointerSignal) {
                  FocusScope.of(context).requestFocus(_focusNode);
                  if (pointerSignal is PointerScrollEvent) {
                    //print("scroll ${pointerSignal.scrollDelta.dy}");
                    widget._settings.scroll(pointerSignal.scrollDelta.dy);
                  }
                },
                onPointerHover: (event) {
                  setState(() {
                    widget._settings.onHover(event.localPosition);
                  });
                  widget.onChanged();
                },
                child: GestureDetector(
                  onHorizontalDragStart: (DragStartDetails ev) {
                    print("onHorizontalDragStart ${ev.kind?.index}");
                    FocusScope.of(context).requestFocus(_focusNode);
                    widget._settings.startMoving(ev.localPosition.dx);
                    widget.onChanged();
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails ev) {
                    setState(() {
                      widget._settings.updateMoving(ev.localPosition.dx);
                    });
                    widget.onChanged();
                  },
                  onHorizontalDragEnd: (DragEndDetails ev) {
                    setState(() {
                      widget._settings.finishMoving();
                    });
                    widget.onChanged();
                  },
                  onScaleStart: (details) {
                    print("GestureDetector::onScaleStart");
                    FocusScope.of(context).requestFocus(_focusNode);
                    widget._settings.startVMoving(
                        details.localFocalPoint.dx, details.localFocalPoint.dy);
                    widget.onChanged();
                    /*map.startMoving(
                        details.pointerCount, details.localFocalPoint);*/
                  },
                  onScaleUpdate: (details) {
                    print(
                        "GestureDetector::onScaleUpdate ${details.scale} ${details.verticalScale}");
                    setState(() {
                      widget._settings.updateVMoving(
                          details.localFocalPoint.dy, details.verticalScale);
                    });
                    widget.onChanged();
                    /*map.updateMoving(details.pointerCount,
                        details.localFocalPoint, details.scale);*/
                  },
                  onScaleEnd: (details) {
                    print("GestureDetector::onScaleEnd");
                    //map.stopMoving(details.pointerCount);
                    setState(() {
                      widget._settings.finishVMoving();
                    });
                    widget.onChanged();
                  },
                  onTapDown: (ev) {
                    setState(() {
                      widget._settings.onTapDown(ev.localPosition);
                    });
                    FocusScope.of(context).requestFocus(_focusNode);
                    widget.onChanged();
                  },
                  child: DragTarget<int>(
                    onMove: (details) {},
                    builder: (
                      BuildContext context,
                      List<dynamic> accepted,
                      List<dynamic> rejected,
                    ) {
                      RenderObject? rObject = context.findRenderObject();
                      if (rObject is RenderBox) {
                        lastRenderBox_ = rObject;
                      }
                      return CustomPaint(
                        painter: TimeChartPainter(widget._settings,
                            (int groupTimeRange, int dtBegin, int dtEnd) {
                          //currentGroupTimeRange = groupTimeRange;
                        }),
                        child: Container(),
                        key: UniqueKey(),
                      );
                    },
                    onAcceptWithDetails: (details) {
                      if (lastRenderBox_ != null) {
                        //var localOffset = lastRenderBox_!.globalToLocal(details.offset);
                        var data = details.data;
                        setState(() {
                          //widget._settings.addSeries(data.name);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
