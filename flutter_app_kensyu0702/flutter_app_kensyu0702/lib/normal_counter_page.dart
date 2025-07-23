import 'package:flutter/material.dart';

class NormalCounterPage extends StatelessWidget {
  const NormalCounterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ノーマルカウンター')),
      body: const Center(child: Text('カウンター画面')),
    );
  }
}
