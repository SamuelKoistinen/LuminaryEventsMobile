import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:table_calendar/table_calendar.dart';

void main() =>
    runApp(const MaterialApp(
    home:NavBars(),
    debugShowCheckedModeBanner: false,
  
  ));
class NavBars extends StatefulWidget {
  const NavBars({super.key});

  @override
  _NavBarsState createState() => _NavBarsState();
}

class _NavBarsState extends State<NavBars> {
PersistentTabController _controller = PersistentTabController(initialIndex: 0);

    List<PersistentBottomNavBarItem> _NavBarItems() {
      return [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.home),
          title: "Home",
          activeColorPrimary: Colors.blue,
          inactiveColorPrimary: Colors.grey,
        ),
         PersistentBottomNavBarItem(
          icon: const Icon(Icons.warehouse),
          title: "Varasto",
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
         PersistentBottomNavBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          title: "Kalenteri",
          activeColorPrimary: Colors.green,
          inactiveColorPrimary: Colors.grey,
        ), 
      ];
    }
  
   List<Widget> _screens() {
    return [
      HomeScreen(),
      VarastoScreen(),
      KalenteriScreen(),
    ];
   }
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: PersistentTabView (
          context,
          controller: _controller,
          screens: _screens(),
          items: _NavBarItems(),
          confineInSafeArea: true,
          )
          
        );
      }
}

class KalenteriScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (_MyAppState().calendarcontent());

  }
}
class VarastoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("VarastoScreen"));
  }
}
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("HomeScreen"));
  }
}


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
      appBar: AppBar(title: const Text("HomePage")),
      body: calendarcontent(),
    );
  }
  Widget calendarcontent() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
           Text("Selected Day = " + today.toString().split(" ")[0]),
           const Text("Kalenteri"),
           Container(child: TableCalendar(
            locale: "en_US",
            rowHeight: 43,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, today),
            focusedDay: today,
            firstDay: DateTime.utc(2010,16,10),
            lastDay: DateTime.utc(2030,3,14),
            onDaySelected: _OnDaySelected,
            
            ),
          )

        ],
      ),
    );
  }
}
 
    
  

