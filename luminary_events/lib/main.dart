import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';


void main() =>
    runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const MyApp(),
  
  ));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  DateTime today = DateTime.now();
  void _OnDaySelected(DateTime day,DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HomePage")),
      body: content(),
    );
  }
  Widget content() {
    return Column(
      children: [
        Text("Kalenteri"),
        Container(child: TableCalendar(
          locale: "en_US",
          rowHeight: 43,
          headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true),
          availableGestures: AvailableGestures.all,
          selectedDayPredicate: (day) => isSameDay(day, today),
          focusedDay: today,
          firstDay: DateTime.utc(2010,16,10),
          lastDay: DateTime.utc(2030,3,14),
          onDaySelected: _OnDaySelected,
          
          ),

        ) 
      ],
    );
  }
}
 
    
  

