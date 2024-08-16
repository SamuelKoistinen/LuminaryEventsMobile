import 'package:flutter/material.dart';
import 'package:luminary_events/CalendarSivu.dart';
import 'utils.dart';

final List<String> entries = <String>['Haloo', 'Miuku Mauku', '59258'];
final List<int> colorCodes = <int>[200, 100, 50];

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.useRouter = false});

  final bool useRouter;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 30, right: 8, left: 8, bottom: 8),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 50,
          color: Colors.blue[colorCodes[index]],
          child: Center(child: Text('Event: ${entries[index]}')),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}
