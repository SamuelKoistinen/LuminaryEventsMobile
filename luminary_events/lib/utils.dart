import 'dart:convert';
import 'dart:collection';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'env.dart';

/// Calendar event class.
class Event {
  final int id;
//  final Double price;
  final String title;
  final String orderStartDate;
  final int orderLengthDays;
  final String orderEndDate;
//  final String orderDue;
  final String customerName;
//  final String customerPhone;
//  final String customerEmail;
//  final String orderStatus;
//  final Bool paymentResolved;
//  final String message;
  final List<String> contents;

  const Event({
    required this.id,
//    required this.price,
    required this.title,
    required this.orderStartDate,
    required this.orderLengthDays,
    required this.orderEndDate,
//    required this.orderDue,
    required this.customerName,
//    required this.customerPhone,
//    required this.customerEmail,
//    required this.orderStatus,
//    required this.paymentResolved,
//    required this.message,
    required this.contents,
  });

  @override
  String toString() => title;
}

// Mapping events to the calendar
final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

// Function to fetch event data for a selected day
Future<Map<String, dynamic>> fetchMapData(DateTime selectedDay) async {
  try {
    var response = await http.get(
      Uri.parse('${Env.baseurl}${Env.apikey}${selectedDay.toString()}'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      log('data: $data');
      return data;
    } else {
      throw 'Failed to fetch data: ${response.statusCode}';
    }
  } catch (e) {
    throw 'Exception fetching data: $e';
  }
}

// Function to fetch event data
Future<void> fetchData() async {
  try {
    var response = await http.get(Uri.parse('${Env.baseurl}${Env.apikey}'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      log('data $data');
      kEvents.clear();
      for (var item in data) {
        int eventId = item['id'];
        String? orderStartDate = item['order_start_date'];
        int? orderLengthDays = item['order_length_days'];
        String? orderEndDate = item['order_end_date'];
        String? customerName = item['customer_name'];
        dynamic contentsData = item['contents'];
        List<String> contents = [];

        if (contentsData != null) {
          if (contentsData is List<dynamic>) {
            // Handle the case where contentsData is a list
            contents = contentsData
                .map((content) => content['name'].toString())
                .toList();
          } else {
            // Handle other scenarios, like if contentsData is a single map or other types
            // You can add custom logic here based on your requirements
            log('Unexpected contents data format: $contentsData');
          }
        }

        if (orderStartDate != null &&
            orderEndDate != null &&
            orderLengthDays != null &&
            customerName != null) {
          DateTime startDate = DateTime.parse(orderStartDate).toLocal();
          DateTime endDate = startDate.add(Duration(days: orderLengthDays));

          String eventTitle = 'Tilauksen Tekijä: $customerName';
          Event event = Event(
            id: eventId,
            title: eventTitle,
            orderStartDate: orderStartDate,
            orderLengthDays: orderLengthDays,
            orderEndDate: endDate.toIso8601String(),
            customerName: customerName,
            contents: contents,
          );

          for (int i = 0; i < orderLengthDays; i++) {
            DateTime date = startDate.add(Duration(days: i));
            kEvents.putIfAbsent(date, () => []);
            kEvents[date]!.add(event);
          }
        } else {
          log('One or more fields are null in the JSON data');
        }
      }
    } else {
      log('Failed to fetch data: ${response.statusCode}');
    }
  } catch (e) {
    log('Exception: $e');
  }
}

// Function to retrieve events for the next 7 days
List<Event> retrieveEventsForNext7Days() {
  final DateTime today = DateTime.now();
  final List<Event> events = [];

  for (int i = 0; i < 7; i++) {
    final DateTime day =
        DateTime(today.year, today.month, today.day + i); // Normalized date
    if (kEvents.containsKey(day)) {
      final eventsForDay = kEvents[day]!;
      events.addAll(eventsForDay);
    }
  }

  return events;
}

// Function to POST new order to db
Future<void> newData() async {
  try {
    var response = await http.post(Uri.parse('${Env.baseurl}${Env.apikey}'));
    if (response.statusCode == 200) {}
  } catch (e) {
    log('Exception: $e');
  }
}

// Function to PUT order on db
Future<void> upData() async {
  try {
    var response = await http.put(Uri.parse('${Env.baseurl}${Env.apikey}'));
    if (response.statusCode == 200) {}
  } catch (e) {
    log('Exception: $e');
  }
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
