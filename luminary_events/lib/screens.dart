import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:luminary_events/env.dart";
import "package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart";
import 'package:table_calendar/table_calendar.dart';

import '../utils.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.useRouter = false});

  final bool useRouter;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Etusivu")),
        backgroundColor: Colors.indigo,
        body: ListView(
          padding: const EdgeInsets.all(16)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom),
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: TextField(
                decoration: InputDecoration(hintText: "Test Text Field 1"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (useRouter) {
                    context.go("/home/detail");
                  } else {
                    pushScreen(
                      context,
                      settings: const RouteSettings(name: "/home"),
                      screen: const MainScreen2(),
                      pageTransitionAnimation:
                          PageTransitionAnimation.scaleRotate,
                    );
                  }
                },
                child: const Text("Go to Second Screen without Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useRootNavigator: true,
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Exit"),
                      ),
                    ),
                  );
                },
                child: const Text("Popup From Bottom ONTOP Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useRootNavigator: false,
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Exit"),
                      ),
                    ),
                  );
                },
                child: const Text("Popup From Bottom UNDER Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  pushWithNavBar(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) => const ExampleDialog(),
                    ),
                  );
                },
                child: const Text("Push Popup Screen"),
              ),
            ),
          ],
        ),
      );
}

//   -----------------------------------------------------
//  |             kalenterinäkymä on tässä.               |
//   -----------------------------------------------------

//    Kalenterissa ei funktionaalisuutta, statejen kanssa pitäs värkätä ja
//    ehkä tehä tästä oma komponentti mutta en tiiä, pitää miettiä ja tutkii.

class MainScreen2 extends StatefulWidget {
  @override
  _MainScreen2State createState() => _MainScreen2State();

  const MainScreen2({super.key, this.useRouter = false});
  final bool useRouter;
}

class _MainScreen2State extends State<MainScreen2> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Tapahtumakalenteri")),
        backgroundColor: Colors.teal,
        body: TableCalendar(
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            // Use `selectedDayPredicate` to determine which day is currently selected.
            // If this returns true, then `day` will be marked as selected.

            // Using `isSameDay` is recommended to disregard
            // the time-part of compared DateTime objects.
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              // Call `setState()` when updating the selected day
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              // Call `setState()` when updating calendar format
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            // No need to call `setState()` here
            _focusedDay = focusedDay;
          },
        ),
      );
}

class MainScreen3 extends StatelessWidget {
  const MainScreen3({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Varasto")),
        backgroundColor: Colors.deepOrangeAccent,
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              debugPrint(Env.passwordkey);
            },
            child: Text(Env.apikey),
          ),
        ),
      );
}

class ExampleDialog extends StatelessWidget {
  const ExampleDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.3,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          color: Colors.amber,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "This is a modal screen",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Return"),
                ),
              ),
            ],
          ),
        ),
      );
}
