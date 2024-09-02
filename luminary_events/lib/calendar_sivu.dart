import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils.dart';
import 'package:http/http.dart' as http;
import 'env.dart';

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
      .disabled; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _formKey = GlobalKey<FormState>();

  //This is the controller used to edit the new events text field

  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _selectedEvents.dispose();
    super.dispose();
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
      var response =
          await http.delete(Uri.parse('${Env.baseurl}${Env.apikey}/$id'));
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

      var response = await http.post(Uri.parse('${Env.baseurl}${Env.apikey}'),
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
            ?.add(Duration(days: int.parse(_orderLengthController.text) - 1))
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

      var response =
          await http.put(Uri.parse('${Env.baseurl}${Env.apikey}/$id'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonData);
      if (response.statusCode == 201) {
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
    fetchData();
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
                                                    child: Form(
                                                      key: _formKey,
                                                      child: Column(
                                                        children: [
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value!
                                                                      .length >
                                                                  35) {
                                                                return 'Max. 35 merkkiä!';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _customerController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'nimi -> ${e.customerName}'),
                                                          ),
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value ==
                                                                      null ||
                                                                  value
                                                                      .isEmpty) {
                                                                return null;
                                                              } else if (value
                                                                          .length >
                                                                      13 ||
                                                                  value.length <
                                                                      7) {
                                                                return 'Tarkista puhelinnumero!';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _phoneController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Puhelin -> ${e.customerPhone}'),
                                                          ),
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value ==
                                                                      null ||
                                                                  value
                                                                      .isEmpty) {
                                                                return null;
                                                              } else if (value
                                                                          .length >
                                                                      35 ||
                                                                  value.length <
                                                                      4) {
                                                                return 'Tarkista sähköposti!';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _emailController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Email -> ${e.customerEmail}'),
                                                          ),
                                                          TextFormField(
                                                            controller:
                                                                _startDateController
                                                                  ..text = e
                                                                      .orderStartDate
                                                                      .substring(
                                                                          0,
                                                                          10),
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Alkaa ->  ${e.orderStartDate.substring(0, 10)}'),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: [
                                                              DateTextFormatter()
                                                            ],
                                                          ),
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value ==
                                                                  '0') {
                                                                return 'Kesto ei voi olla 0!';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _orderLengthController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Kesto -> ${e.orderLengthDays}'),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly
                                                            ],
                                                          ),
                                                          TextFormField(
                                                            controller:
                                                                _priceController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Hinta -> ${e.price}'),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                          ),
                                                          TextFormField(
                                                            controller:
                                                                _dueDateController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Maksupäivä  -> ${e.orderDue.substring(0, 10)} '),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: [
                                                              DateTextFormatter()
                                                            ],
                                                          ),
                                                          TextFormField(
                                                            controller:
                                                                _orderStatusController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Tilanne -> ${e.orderStatus}'),
                                                          ),
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value ==
                                                                      null ||
                                                                  value
                                                                      .isEmpty) {
                                                                return null;
                                                              } else if (value !=
                                                                      '1' ||
                                                                  value !=
                                                                      '0') {
                                                                return 'Arvon tulee olla 1 tai 0!';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _paymentResolvedController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Maksettu (1/0) -> ${e.paymentResolved}'),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly
                                                            ],
                                                          ),
                                                          TextFormField(
                                                            validator: (value) {
                                                              if (value!
                                                                      .length >
                                                                  300) {
                                                                return 'Viestin enimmäispituus on 300 merkkiä.';
                                                              }
                                                              return null;
                                                            },
                                                            controller:
                                                                _messageController,
                                                            decoration:
                                                                InputDecoration(
                                                                    helperText:
                                                                        'Lisätiedot -> ${e.message}'),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        _selectedEvents.value =
                                                            _getEventsForDay(
                                                                _selectedDay!);
                                                        clearController();
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Peru')),
                                                  TextButton(
                                                    onPressed: () {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        editEvent(e.id);
                                                        clearController();
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                    child:
                                                        const Text('Päivitä'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          textBtn(context, 'Poista', () {
                                            showDialog(
                                                context: context,
                                                builder: (BuildContext
                                                        context) =>
                                                    AlertDialog(
                                                      scrollable: true,
                                                      title: const Text(
                                                          'Haluatko Varmasti Poistaa Tapahtuman?'),
                                                      content: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                              _selectedEvents
                                                                      .value =
                                                                  _getEventsForDay(
                                                                      _selectedDay!);
                                                              clearController();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Peru')),
                                                        TextButton(
                                                            onPressed: () {
                                                              deleteEvent(e.id);
                                                              _selectedEvents
                                                                      .value =
                                                                  _getEventsForDay(
                                                                      _selectedDay!);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Poista')),
                                                      ],
                                                    ));
                                            ;
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
        floatingActionButton: FloatingActionButton(
          heroTag: "btn2",
          shape: CircleBorder(),
          onPressed: () {
            // todo: Show dialog to user to input event
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      scrollable: true,
                      title: const Text('Uusi tapahtuma'),
                      content: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Nimi!';
                                  } else if (value.length > 35) {
                                    return 'Max. 35 merkkiä!';
                                  }
                                  return null;
                                },
                                controller: _customerController,
                                decoration: const InputDecoration(
                                    helperText: 'Asiakkaan nimi'),
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Puhelinnumero!';
                                  } else if (value.length > 13 ||
                                      value.length < 7) {
                                    return 'Tarkista puhelinnumero!';
                                  }
                                  return null;
                                },
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                    helperText: 'Puhelin'),
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Sähköpostiosoite!';
                                  } else if (value.length > 35 ||
                                      value.length < 4) {
                                    return 'Tarkista sähköposti!';
                                  }
                                  return null;
                                },
                                controller: _emailController,
                                decoration:
                                    const InputDecoration(helperText: 'Email'),
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Tilauksen kesto!';
                                  } else if (value == '0') {
                                    return 'Kesto ei voi olla 0!';
                                  }
                                  return null;
                                },
                                controller: _orderLengthController,
                                decoration: const InputDecoration(
                                    helperText: 'Kesto (pelkkä numero)'),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Hinta!';
                                  }
                                  return null;
                                },
                                controller: _priceController,
                                decoration: const InputDecoration(
                                    helperText: 'Hinta (pelkkä numero)'),
                                keyboardType: TextInputType.number,
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Syötä Maksupäivä! (YYYY-MM-DD)';
                                  }
                                  return null;
                                },
                                controller: _dueDateController,
                                decoration: const InputDecoration(
                                    helperText: 'Maksupäivä (YYYY-MM-DD)'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [DateTextFormatter()],
                                onChanged: (String value) {},
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value!.length > 300) {
                                    return 'Viestin enimmäispituus on 300 merkkiä.';
                                  }
                                  return null;
                                },
                                controller: _messageController,
                                decoration: const InputDecoration(
                                    helperText: 'Viesti (Valinnainen)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                            onPressed: () {
                              _selectedEvents.value =
                                  _getEventsForDay(_selectedDay!);
                              clearController();
                              Navigator.pop(context);
                            },
                            child: const Text('Peru')),
                        ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                postEvent();
                                _selectedEvents.value =
                                    _getEventsForDay(_selectedDay!);
                                clearController();
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Tallenna')),
                      ],
                    ));
          },
          child: const Icon(Icons.add),
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
}

class DateTextFormatter extends TextInputFormatter {
  static const _maxChars = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String separator = '-';
    var text = _format(
      newValue.text,
      oldValue.text,
      separator,
    );

    return newValue.copyWith(
      text: text,
      selection: updateCursorPosition(
        oldValue,
        text,
      ),
    );
  }

  String _format(
    String value,
    String oldValue,
    String separator,
  ) {
    var isErasing = value.length < oldValue.length;
    var isComplete = value.length > _maxChars + 2;

    if (!isErasing && isComplete) {
      return oldValue;
    }

    value = value.replaceAll(separator, '');
    final result = <String>[];

    for (int i = 0; i < math.min(value.length, _maxChars); i++) {
      result.add(value[i]);
      if ((i == 3 || i == 5) && i != value.length - 1) {
        result.add(separator);
      }
    }

    return result.join();
  }

  TextSelection updateCursorPosition(
    TextEditingValue oldValue,
    String text,
  ) {
    var endOffset = math.max(
      oldValue.text.length - oldValue.selection.end,
      0,
    );

    var selectionEnd = text.length - endOffset;

    return TextSelection.fromPosition(TextPosition(offset: selectionEnd));
  }
}
