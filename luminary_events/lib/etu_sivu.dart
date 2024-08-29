import 'package:flutter/material.dart';
import 'utils.dart';
import 'package:intl/intl.dart';

// Entry point of the Flutter application
void main() {
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(), // Sets the MainScreen as the home screen
    );
  }
}

// MainScreen that manages state and displays the list of events
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<void> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture =
        fetchData(); // Start fetching data when the screen initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Etusivu"),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 34, 32, 33),
      body: FutureBuilder<void>(
        future: _fetchFuture, // Wait for the fetchData() to complete
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}')); // Error message
          } else {
            final List<Event> events = retrieveEventsForNext7Days();
            if (events.isEmpty) {
              return const Center(
                  child: Text('No events found.')); // No events message
            }

            return ListView.separated(
              padding: const EdgeInsets.only(top: 10),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                final event = events[index];
                final StartDateToBeFormatted =
                    DateTime.parse(event.orderStartDate);
                final EndDateToBeFormatted = DateTime.parse(event.orderEndDate);
                final formatter = DateFormat('dd-MM-yyyy');
                final StartDate = formatter.format(StartDateToBeFormatted);
                final EndDate = formatter.format(EndDateToBeFormatted);
                return Container(
                  color: const Color.fromARGB(255, 75, 149, 209),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      'From ${StartDate} to ${EndDate}\n'
                      'Customer: ${event.customerName}\n'
                      'Message: ${event.message}',
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
            );
          }
        },
      ),
    );
  }
}
