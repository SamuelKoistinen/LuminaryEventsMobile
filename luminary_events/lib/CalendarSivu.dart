import 'dart:convert';

import "package:flutter/material.dart";
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
  final _orderStartController = TextEditingController();
  final _orderLengthController = TextEditingController();
  final _orderEndController = TextEditingController();
  final _priceController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _contentController = TextEditingController();
  void clearController() {
    _customerController.clear();
    _orderStartController.clear();
    _orderEndController.clear();
    _orderLengthController.clear();
    _priceController.clear();
    _dueDateController.clear();
    _phoneController.clear();
    _emailController.clear();
    _contentController.clear();
  }

  // Function to DELETE order on db
  deleteEvent(int id) async {
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
      print('Exception: $e');
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
                                                    maxLines: 1,
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
                                                        'Kesto: ${e.orderLengthDays} päivää'),
                                                    Text('tunniste: ${e.id}'),
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
                                          textBtn(context, 'Muokkaa', () {}),
                                          textBtn(context, 'Poista', () {
                                            deleteEvent(e.id);
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

// ALERT DIALOG
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
              decoration: const InputDecoration(helperText: 'Tilauksen kesto'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              _addEvent(_selectedDay ?? DateTime.now());
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
              clearController();
              context.pop();
            },
            child: const Text('Lisää Tapahtuma'))
      ],
    );
  }

  void _clearTextField() {
    _textFieldController.clear();
  }

  void _addEvent(DateTime selectedDate) {
    if (kEvents.containsKey(selectedDate)) {
      kEvents[selectedDate]!.add(Event(
          id: 1, // PLACEHOLDER
          customerName: _customerController.text,
          title: _customerController.text,
          orderStartDate: _orderStartController.text,
          orderLengthDays: int.parse(_orderLengthController.text),
          orderEndDate: _orderEndController.text,
          contents:
              json.decode(_contentController.text).cast<String>().toList()));
    } else {
      kEvents[selectedDate] = [
        Event(
            id: 1, // PLACEHOLDER
            customerName: _customerController.text,
            title: _customerController.text,
            orderStartDate: _orderStartController.text,
            orderLengthDays: int.parse(_orderLengthController.text),
            orderEndDate: _orderEndController.text,
            contents:
                json.decode(_contentController.text).cast<String>().toList())
      ];
    }

    setState(() {});
  }
}
