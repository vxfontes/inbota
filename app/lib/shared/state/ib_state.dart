import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

abstract class IBController {
  void dispose();
}

abstract class IBState<T extends StatefulWidget, C extends IBController> extends State<T> {
  late final C controller;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<C>();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
