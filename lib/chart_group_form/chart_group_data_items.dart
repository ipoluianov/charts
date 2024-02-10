import 'package:flutter/material.dart';

class ChartGroupDataItems extends StatefulWidget {
  const ChartGroupDataItems({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChartGroupDataItemsState();
  }
}

class ChartGroupDataItemsState extends State<ChartGroupDataItems> {
  @override
  void initState() {
    super.initState();
  }

  List<DataItemsGroup> _groups = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _groups.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        e.expanded = !e.expanded;
                      });
                    },
                    child: Container(
                      color: Colors.blue.withOpacity(0.5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.blur_on,
                          ),
                          Expanded(
                            child: Draggable<DataItemsObject>(
                              data: DataItemsObject(
                                  e.name, e.name, DataItemsObjectType.unit),
                              feedback: Container(
                                // height: 30,
                                padding: const EdgeInsets.all(6),
                                width: 200,
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: Colors.green,
                                    )),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      e.displayName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: "Roboto",
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.normal,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: e.items.map<Widget>(
                                        (item) {
                                          return Text(
                                            item.fullName,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontFamily: "Roboto",
                                              fontWeight: FontWeight.normal,
                                              fontStyle: FontStyle.normal,
                                              decoration: TextDecoration.none,
                                            ),
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.all(3),
                                child: Text(
                                  e.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          e.expanded
                              ? const Icon(Icons.keyboard_arrow_up_outlined)
                              : const Icon(Icons.keyboard_arrow_down_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
                e.expanded
                    ? Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: e.items.map((item) {
                            return Draggable<DataItemsObject>(
                              data: DataItemsObject(item.fullName, item.name,
                                  DataItemsObjectType.dataItem),
                              feedback: Container(
                                //height: 30,
                                padding: const EdgeInsets.all(6),
                                width: 200,
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: Colors.green,
                                    )),
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: "Roboto",
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FontStyle.normal,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  //color: Colors.red,
                                  margin: const EdgeInsets.all(1),
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    bottom: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.blue.withOpacity(0.3)),
                                    ),
                                  ),
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : Container(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DataItemsGroup {
  String name;
  String displayName;
  bool expanded = false;
  List<DataItemsItem> items = [];
  DataItemsGroup(this.name, this.displayName);
}

class DataItemsItem {
  String fullName;
  String name;
  DataItemsItem(this.fullName, this.name);
}

class DataItemsObject {
  String name;
  DataItemsObjectType type;
  String displayName;
  DataItemsObject(this.name, this.displayName, this.type);
}

enum DataItemsObjectType { dataItem, unit }
