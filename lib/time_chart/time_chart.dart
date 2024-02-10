import 'dart:async';

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

class TimeRange {
  final String name;
  final String value;
  TimeRange(this.name, this.value);
}

class TimeChartState extends State<TimeChart> with TickerProviderStateMixin {
  late Timer _timerUpdateTimeRange =
      Timer.periodic(const Duration(milliseconds: 1000), (timer) {});

  final DataFile _dataFile = DataFile();

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
    setDisplayRange(DateTime(2020, 1, 1).microsecondsSinceEpoch.toDouble(),
        DateTime(2020, 2, 2).microsecondsSinceEpoch.toDouble());
  }

  void updateTimes() {
    setState(() {
      double w = widget._settings.horScale.width;
      if (w < 1) {
        return;
      }

      double r = widget._settings.horScale.displayMax -
          widget._settings.horScale.displayMin;
      int timePerPixel = (r / w).round();

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
              timePerPixel);

          if (data.isNotEmpty) {
            series.itemHistory = data;
          }
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

  /*
DragTarget<DataItemsObject>(
      builder: (
          BuildContext context,
          List<dynamic> accepted,
          List<dynamic> rejected,
          ) {
        return text();


                },
      onAcceptWithDetails: (details) {
        var data = details.data;
        var areaIndex = widget._settings.findAreaIndexByXY(details.offset.dx, details.offset.dy);
        if (areaIndex < 0) {
          setState(() {
            widget._settings.areas
                .add(TimeChartSettingsArea(widget.conn, <TimeChartSettingsSeries>[TimeChartSettingsSeries(widget.conn, data.name, [], Colors.blueAccent)], false));
          });
        } else {
          setState(() {
            widget._settings.areas[areaIndex].series.add(TimeChartSettingsSeries(widget.conn, data.name, [], Colors.blueAccent));
          });

        }
      },
    );

   */

  RenderBox? lastRenderBox_;

  MouseCursor chartCursor() {
    return widget._settings.mouseCursor();

    /*if (widget._settings.keyControl) {
      print("cursor wait");
      return SystemMouseCursors.wait;
    }*/
    return SystemMouseCursors.basic;
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
                  onTapDown: (ev) {
                    setState(() {
                      widget._settings.onTapDown(ev.localPosition);
                    });
                    FocusScope.of(context).requestFocus(_focusNode);
                    widget.onChanged();
                  },
                  /*onVerticalDragStart: (DragStartDetails ev) {
                settings.startMovingY(ev.localPosition.dy);
              },
              onVerticalDragUpdate: (DragUpdateDetails ev) {
                setState(() {
                  settings.updateMovingY(ev.localPosition.dy);
                });
              },
              onVerticalDragEnd: (DragEndDetails ev) {
                setState(() {
                  settings.finishMovingY();
                });
              },*/
                  /*
              onDoubleTap: () {
                settings.doubleTap();
              },*/
                  child: DragTarget<int>(
                    onMove: (details) {
                      //.findRenderObject();
                      //Converts the global coordinates to the local coordinates of the current widget.
                      //Offset center = box.globalToLocal(Offset(info.dx, info.dy));

                      //print("MOVE: ${details.offset}");
                    },
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
