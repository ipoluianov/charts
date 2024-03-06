import 'package:flutter/material.dart';

List<Widget> buildList(BuildContext context) {
  List<Widget> res = [];
  return res;
}

Future<String?> showInstrumentsListDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Instruments List"),
        content: SingleChildScrollView(
          child: ListBody(
            children: buildList(context),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
