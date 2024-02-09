import 'package:flutter/material.dart';

class MainForm extends StatefulWidget {
  const MainForm({super.key});

  @override
  State<StatefulWidget> createState() {
    return MainFormState();
  }
}

class MainFormState extends State<MainForm> {
  Widget buildContent(BuildContext context) {
    return const Text("123");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildContent(context),
    );
  }
}
