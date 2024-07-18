import "package:flutter/material.dart";
import 'package:table_calendar/table_calendar.dart';
import '../utils.dart';




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