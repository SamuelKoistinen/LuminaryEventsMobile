import 'dart:convert';
import 'dart:developer';
import "package:flutter/material.dart";
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

//     ⢰⣶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⢰⠀
//   ⠀  ⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣤⣶⣾⣿⣿⣿⠀
//   ⠀  ⠘⢿⣿⣿⣿⣿⣦⣀⣀⣀⣄⣀⣀⣠⣀⣤⣶⣿⣿⣿⣿⣿⠇⠀
//   ⠀⠀   ⠈⠻⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀
//     ⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀
//     ⠀⠀⠀⢠⣿⣿⡏⠆⢹⣿⣿⣿⣿⣿⣿⠒⠈⣿⣿⣿⣇⠀⠀⠀⠀
//     ⠀⠀⠀⣼⣿⣿⣷⣶⣿⣿⣛⣻⣿⣿⣿⣶⣾⣿⣿⣿⣿⠀⠀⠀
//     ⠀⠀⠀⡁⠀⠈⣿⣿⣿⣿⢟⣛⡻⣿⣿⣿⣟⠀⠀⠈⣿⡇⠀⠀⠀
//     ⠀⠀⠀⢿⣶⣿⣿⣿⣿⣿⡻⣿⡿⣿⣿⣿⣿⣶⣶⣾⣿⣿⠀⠀⠀
//     ⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀
//     ⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀

//  𝐏𝐈𝐂𝐊𝐀𝐂𝐇𝐔𝐏𝐈𝐂𝐊𝐀𝐂𝐇𝐔𝐏𝐈𝐂𝐊𝐀𝐂𝐇𝐔𝐏𝐈𝐂𝐊𝐀𝐂𝐇𝐔𝐏𝐈𝐂𝐊𝐀𝐂𝐇𝐔

//   -----------------------------------------------------
//  |             kalenterinäkymä on tässä.               |
//   -----------------------------------------------------

// HUOM! Kalenterinäkymässä tapahtuman poisto parhaillaan poistaa
// kaikki päivän tapahtumat, kun sen reworkkaa toimimaan tietokannan kautta,
// varmista että muokkaus ja poisto toimivat oikein.

class CalendarSivu extends StatefulWidget {
  const CalendarSivu({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EventCalendarScreenState createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<CalendarSivu> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  //This is the controller used to edit the new events text field

  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();

    initializeData();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  void initializeData() async {
    await fetchData();
    setState(() => {});
  }

//*GET EVENTS PER DAY
  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

//*GET EVENT RANGE
  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return [
      for (final day in days) ..._getEventsForDay(day),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start!;
      _rangeEnd = end; //! exception error (null call a null value)
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // *`start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  final _customerController = TextEditingController();
  final _orderLengthController = TextEditingController();
  final _priceController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _startDateController = TextEditingController();
  final _orderStatusController = TextEditingController();
  final _paymentResolvedController = TextEditingController();
  void clearController() {
    _customerController.clear();
    _orderLengthController.clear();
    _priceController.clear();
    _dueDateController.clear();
    _phoneController.clear();
    _emailController.clear();
    _messageController.clear();
    _startDateController.clear();
    _orderStatusController.clear();
    _paymentResolvedController.clear();
  }

  // DELETE REQUEST
  void deleteEvent(int id) async {
    try {
      var response = await http.delete(
          Uri.parse('${dotenv.env['BASEURL']}${dotenv.env['APIKEY']}/$id'));
      if (response.statusCode == 200) {
        setState(() {
          _selectedEvents.value.clear();
          _getEventsForDay;
        });
      }
    } catch (e) {
      log('Exception: $e');
    }
  }

  // POST REQUEST
  void postEvent() async {
    try {
      var data = jsonEncode(<String, dynamic>{
        'total_price': double.parse(_priceController.text),
        'order_created_at': DateTime.now().toIso8601String().substring(0, 10),
        'order_start_date': _selectedDay?.toIso8601String().substring(0, 10),
        'order_length_days': int.parse(_orderLengthController.text),
        'order_end_date': _selectedDay
            ?.add(Duration(days: int.parse(_orderLengthController.text) - 1))
            .toIso8601String()
            .substring(0, 10),
        'payment_due_date': DateTime.parse(_dueDateController.text)
            .toIso8601String()
            .substring(0, 10),
        'customer_name': _customerController.text,
        'customer_phone_number': _phoneController.text,
        'customer_email': _emailController.text,
        'order_status': 'received',
        'payment_resolved': 0,
        'message': _messageController.text
      });

      var response = await http.post(
          Uri.parse('${dotenv.env['BASEURL']}${dotenv.env['APIKEY']}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: data);
      if (response.statusCode == 201) {
        log('data: $data');
        setState(() {
          _selectedEvents.value.clear();
          _getEventsForDay;
        });
      } else {
        // If the server returns an error response, throw an exception
        throw Exception('Code: ${response.statusCode}. Failed to post data');
      }
    } catch (e) {
      log('Exception: $e');
    }
  }

// PUT REQUEST
  void editEvent(int id) async {
    try {
      Map<String, dynamic> data = {
        'total_price': double.tryParse(_priceController.text),
        'order_start_date': DateTime.tryParse(_startDateController.text)
            ?.toIso8601String()
            .substring(0, 10),
        'order_length_days': int.tryParse(_orderLengthController.text),
        'order_end_date': DateTime.tryParse(_startDateController.text)
            ?.add(Duration(days: int.parse(_orderLengthController.text)))
            .toIso8601String()
            .substring(0, 10),
        'payment_due_date': DateTime.tryParse(_dueDateController.text)
            ?.toIso8601String()
            .substring(0, 10),
        'customer_name': _customerController.text,
        'customer_phone_number': _phoneController.text,
        'customer_email': _emailController.text,
        'order_status': 'received',
        'payment_resolved': int.tryParse(_paymentResolvedController.text),
        'message': _messageController.text
      };

      data.removeWhere((key, value) => value == null);
      String jsonData = jsonEncode(data);

      var response = await http.put(
          Uri.parse('${dotenv.env['BASEURL']}${dotenv.env['APIKEY']}/$id'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonData);
      if (response.statusCode == 200) {
        log('data: $jsonData');
        setState(() {
          _selectedEvents.value.clear();
          _getEventsForDay;
        });
      } else {
        // If the server returns an error response, throw an exception
        throw Exception('Code: ${response.statusCode}. Failed to post data');
      }
    } catch (e) {
      log('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Tapahtumakalenteri")),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Text(
                  textAlign: TextAlign.center,
                  DateFormat('dd-MM-yyyy').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TableCalendar<Event>(
                headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(),
                        color: Theme.of(context).colorScheme.tertiaryContainer),
                    formatButtonVisible: false,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onInverseSurface)),
                locale: 'fi_FI',
                firstDay: kFirstDay,
                lastDay: kLastDay,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                      border: Border.all(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer),
                      color: Theme.of(context).colorScheme.primary),
                  selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onTertiaryContainer),
                  todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onTertiaryContainer),
                  // Use `CalendarStyle` to customize the UI
                  outsideDaysVisible: false,
                ),
                onDaySelected: _onDaySelected,
                onRangeSelected: _onRangeSelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onInverseSurface),
                child: ValueListenableBuilder(
                  builder: (context, value, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: value
                          .map((e) => Card(
                              color: Colors.white,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 14),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                  child: Column(children: [
                                                Text(
                                                    maxLines: 5,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 16),
                                                    e.title),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(children: [
                                                    Text(
                                                        'id: ${e.id} jätetty: ${e.orderCreatedAt.substring(5, 10)}, Tilanne: ${e.orderStatus}, hinta: ${e.price}'),
                                                    Text(
                                                        'Tapahtuma ${e.orderStartDate.substring(5, 10)} - ${e.orderEndDate.substring(5, 10)}, Kesto: ${e.orderLengthDays} pv'),
                                                    Text(
                                                        'Maksutilanne: ${e.paymentResolved}, Eräpäivä: ${e.orderDue.substring(5, 10)}'),
                                                    Text(
                                                        'Email: ${e.customerEmail}'),
                                                    Text(
                                                        'Tele: ${e.customerPhone}'),
                                                    Text('"${e.message}"'),
                                                  ]),
                                                )
                                              ])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          textBtn(context, 'Muokkaa', () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                scrollable: true,
                                                title: Text(
                                                    'Tapahtuman ${e.id} muokkauslomake.'),
                                                content: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Column(
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            _customerController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'nimi -> ${e.customerName}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _phoneController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Puhelin -> ${e.customerPhone}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _emailController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Email -> ${e.customerEmail}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _startDateController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Alkaa ->  ${e.orderStartDate.substring(0, 10)}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _orderLengthController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Kesto -> ${e.orderLengthDays}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _priceController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Hinta -> ${e.price}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _dueDateController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Maksupäivä  -> ${e.orderDue.substring(0, 10)} '),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _orderStatusController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Tilanne -> ${e.orderStatus}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _paymentResolvedController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Maksettu (1/0) -> ${e.paymentResolved}'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            _messageController,
                                                        decoration: InputDecoration(
                                                            helperText:
                                                                'Lisätiedot -> ${e.message}'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      editEvent(e.id);
                                                      Navigator.pop(context);
                                                    },
                                                    child:
                                                        const Text('Päivitä'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          textBtn(context, 'Poista', () {
                                            deleteEvent(e.id);
                                            _selectedEvents.value =
                                                _getEventsForDay(_selectedDay!);
                                          }),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )))
                          .toList(),
                    );
                  },
                  valueListenable: _selectedEvents,
                ),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "btn2",
          onPressed: () {
            // todo: Show dialog to user to input event
            showDialog(
                context: context, builder: (_) => _dialogWidget(context));
          },
          label: const Text('Uusi Tapahtuma'),
          icon: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Widget textBtn(BuildContext context, String text, VoidCallback voidCallback) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          voidCallback();
        },
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

// UUSI TAPAHTUMA LOMAKE
  AlertDialog _dialogWidget(BuildContext context) {
    return AlertDialog.adaptive(
      scrollable: true,
      title: const Text('Uusi tapahtuma'),
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(helperText: 'Asiakkaan nimi'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(helperText: 'Puhelin'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(helperText: 'Email'),
            ),
            TextField(
              controller: _orderLengthController,
              decoration:
                  const InputDecoration(helperText: 'Kesto (pelkkä numero)'),
            ),
            TextField(
              controller: _priceController,
              decoration:
                  const InputDecoration(helperText: 'Hinta (pelkkä numero)'),
            ),
            TextField(
              controller: _dueDateController,
              decoration:
                  const InputDecoration(helperText: 'Maksupäivä (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(helperText: 'Lisätiedot'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              postEvent();
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
              clearController();
              context.pop();
            },
            child: const Text('Tallenna')),
      ],
    );
  }
}
