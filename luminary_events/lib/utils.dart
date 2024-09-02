import 'dart:convert';
import 'dart:collection';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

/// Calendar event class.
class Event {
  final int id;
  final int price;
  final String title;
  final String orderCreatedAt;
  final String orderStartDate;
  final int orderLengthDays;
  final String orderEndDate;
  final String orderDue;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String orderStatus;
  final int paymentResolved;
  final String message;

  const Event({
    required this.id,
    required this.price,
    required this.title,
    required this.orderCreatedAt,
    required this.orderStartDate,
    required this.orderLengthDays,
    required this.orderEndDate,
    required this.orderDue,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.orderStatus,
    required this.paymentResolved,
    required this.message,
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
      Uri.parse(
          '${dotenv.env['BASEURL']}${dotenv.env['APIKEY']}${selectedDay.toString()}'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      //log('data: $data');
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
    var response = await http
        .get(Uri.parse('${dotenv.env['BASEURL']}${dotenv.env['APIKEY']}'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      //log('data $data');
      kEvents.clear();
      for (var item in data) {
        int eventId = item['id'];
        int? price = item['total_price'];
        String? orderCreatedAt = item['order_created_at'];
        String? orderStartDate = item['order_start_date'];
        int? orderLengthDays = item['order_length_days'];
        String? orderEndDate = item['order_end_date'];
        String? orderDue = item['payment_due_date'];
        String? customerName = item['customer_name'];
        String? customerphone = item['customer_phone_number'];
        String? customerEmail = item['customer_email'];
        String? orderStatus = item['order_status'];
        int? paymentResolved = item['payment_resolved'];
        String? message = item['message'];

        // if (contentsData != null) {
        //   if (contentsData is List<dynamic>) {
        //     // Handle the case where contentsData is a list
        //     contents = contentsData
        //         .map((content) => content['name'].toString())
        //         .toList();
        //   } else {
        //     // Handle other scenarios, like if contentsData is a single map or other types
        //     // You can add custom logic here based on your requirements
        //     print('Unexpected contents data format: $contentsData');
        //   }
        // }

        if (price != null &&
            orderCreatedAt != null &&
            orderStartDate != null &&
            orderEndDate != null &&
            orderLengthDays != null &&
            orderDue != null &&
            customerName != null &&
            customerphone != null &&
            customerEmail != null &&
            orderStatus != null &&
            paymentResolved != null &&
            message != null) {
          DateTime startDate = DateTime.parse(orderStartDate).toLocal();
          DateTime endDate = DateTime.parse(orderEndDate).toLocal();

          String eventTitle = '$customerName:n Tapahtuma #$eventId';
          Event event = Event(
            id: eventId,
            price: price,
            title: eventTitle,
            orderCreatedAt: orderCreatedAt,
            orderStartDate: startDate.toString(),
            orderLengthDays: orderLengthDays,
            orderEndDate: endDate.toString(),
            customerName: customerName,
            customerPhone: customerphone,
            customerEmail: customerEmail,
            orderStatus: orderStatus,
            paymentResolved: paymentResolved,
            message: message,
            orderDue: orderDue,
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
    final DateTime day = DateTime(today.year, today.month, today.day + i);

    // Normalize the date to ensure it matches the keys in kEvents
    final DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    if (kEvents.containsKey(normalizedDay)) {
      final eventsForDay = kEvents[normalizedDay]!;
      log('Events for $normalizedDay:');

      for (var event in eventsForDay) {
        log('- ${event.title}');
        log('- Order Start Date: ${event.orderStartDate}');
        log('- Order Length Days: ${event.orderLengthDays}');
        log('- Order End Date: ${event.orderEndDate}');
        log('- Customer Name: ${event.customerName}');

        // Add the event to the list
        events.add(event);
      }
    }
  }

  return events;
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
