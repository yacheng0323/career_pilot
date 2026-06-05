import 'package:flutter/material.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('求職追蹤')),
      body: const Center(child: Text('Kanban 看板即將上線')),
    );
  }
}
