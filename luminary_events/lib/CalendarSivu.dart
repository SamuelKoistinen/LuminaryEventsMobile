import "package:flutter/material.dart";
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils.dart';

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
  Map<DateTime, List<Event>> events = {};
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    loadPreviousEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

//*GET EVENTS PER DAY
  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
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

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  void clearController() {
    _titleController.clear();
    _descriptionController.clear();
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
              TableCalendar(
                headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(),
                        color: Theme.of(context).colorScheme.tertiaryContainer),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onInverseSurface)),
                firstDay: DateTime.utc(2000, 12, 31),
                lastDay: DateTime.utc(2030, 01, 01),
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
                                                  child: Text.rich(
                                                      TextSpan(children: [
                                                    TextSpan(
                                                      text: e.description,
                                                    ),
                                                  ])),
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
                                            setState(() {
                                              _selectedEvents.value.clear();
                                              _getEventsForDay;
                                            });
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
              controller: _titleController,
              decoration: const InputDecoration(helperText: 'Nimi'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(helperText: 'Kuvaus'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              events.addAll({
                _selectedDay!: [
                  ..._selectedEvents.value,
                  Event(
                      title: _titleController.text,
                      description: _descriptionController.text)
                ]
              });
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
              clearController();
              context.pop();
            },
            child: const Text('Lähetä'))
      ],
    );
  }

  void loadPreviousEvents() {
    events = {
      _selectedDay!: [const Event(title: '', description: '')],
      _selectedDay!: [const Event(title: '', description: '')]
    };
  }
}
