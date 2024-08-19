import 'package:flutter/material.dart';
import 'utils.dart' as utils;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.useRouter = false});

  final bool useRouter;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 30, right: 8, left: 8, bottom: 8),
      itemCount: 4,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 50,
          color: Colors.blue,
          child: Center(child: Text('Event: ${utils.kLastDay}')),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}
