import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MainScreen3 extends StatefulWidget {
  const MainScreen3({super.key});

  @override
  State<MainScreen3> createState() => _MainScreen3State();
}

class _MainScreen3State extends State<MainScreen3> {
  bool unsavedChanges = false;

  final TextEditingController _controller = TextEditingController();

  List unsavedChangesList = [];
  List changedSubIDs = [];
  int stockChange = 0;

  bool qrCodeProcessed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List deviceCategories = [
    {"name": 'kokoääni', "devices": []},
    {"name": 'sub', "devices": []},
    {"name": 'dj', "devices": []},
    {"name": 'lavatekniikka', "devices": []},
  ];

  @override
  void initState() {
    super.initState();
    getDatabaseInfo();
  }

  getDatabaseInfo() async {
    for (var category in deviceCategories) {
      category['devices'].clear();
    }
    final response =
        await http.get(Uri.parse("${dotenv.env['BASEURL']}devices"));
    if (response.statusCode == 200) {
      final List parsedList = json.decode(response.body);
      for (var device in parsedList) {
        for (var category in deviceCategories) {
          if (device['type'] == category['name']) {
            category['devices'].add(device);
          }
        }
      }
      setState(() => {});
    } else {
      throw Exception('Failed to load database info');
    }
  }

  sendUpdatedData() async {
    for (var device in unsavedChangesList) {
      final response = await http.put(
        Uri.parse("${dotenv.env['BASEURL']}devices/${device['id']}"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'current_stock': device['current_stock'],
          'sub_ids': device['sub_ids'],
        }),
      );
      if (response.statusCode == 201) {
      } else {
        throw Exception('Failed to send updated data');
      }
    }
    unsavedChangesList.clear();
    getDatabaseInfo();
  }

  setupSubIDs(String? dbSubIDs) {
    if (dbSubIDs == null) {
      return;
    }
    changedSubIDs.clear();
    stockChange = 0;

    dbSubIDs.split(' ').forEach((element) {
      if (element != '') changedSubIDs.add(element);
    });
  }

  processBarCode(String? barcode) async {
    qrCodeProcessed = true;

    if (barcode == null) {
      return;
    }
    var barcodeSplit = barcode.split('_');
    if (barcodeSplit.length != 2) {
      return;
    }
    // ignore: prefer_typing_uninitialized_variables
    var device;
    final response = await http
        .get(Uri.parse("${dotenv.env['BASEURL']}devices/${barcodeSplit[0]}"));
    if (response.statusCode == 200) {
      device = json.decode(response.body);
    } else {
      throw Exception('Failed to load database info');
    }

    setupSubIDs(device['sub_ids']);

    changedSubIDs.contains(barcode)
        ? {
            changedSubIDs.removeWhere((element) => element == barcode),
            stockChange = stockChange + 1,
          }
        : {
            changedSubIDs.add(barcode),
            stockChange = stockChange - 1,
          };

    String preppedSubIDs = '';
    for (var subID in changedSubIDs) {
      if (preppedSubIDs.isNotEmpty) {
        preppedSubIDs = '$preppedSubIDs ';
      }
      preppedSubIDs = preppedSubIDs + subID;
    }

    if (preppedSubIDs.isEmpty) {
      preppedSubIDs = "empty";
    }

    setState(() {
      for (var unsavedChange in unsavedChangesList) {
        if (unsavedChange['id'] == device['id']) {
          unsavedChange['current_stock'] += stockChange;
          unsavedChange['sub_ids'] = preppedSubIDs;
        }
      }
      unsavedChangesList.add({
        'id': device['id'],
        'current_stock': device['current_stock'] + stockChange,
        'sub_ids': preppedSubIDs
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Varasto")),
        body: Center(
          child: Column(children: [
            Flexible(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(width: 3, color: Color(0xFF201C24)))),
                child: Row(children: [
                  Flexible(
                    flex: 2,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Row(children: [
                          TextButton.icon(
                            onPressed: () {
                              qrCodeProcessed = false;
                              showDialog(
                                  context: context,
                                  builder: (context) => SimpleDialog(
                                        title: null,
                                        contentPadding:
                                            const EdgeInsets.all(20.0),
                                        children: [
                                          SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  10,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height -
                                                  200,
                                              child: MobileScanner(
                                                  controller:
                                                      MobileScannerController(
                                                    detectionSpeed:
                                                        DetectionSpeed
                                                            .noDuplicates,
                                                  ),
                                                  onDetect: (capture) {
                                                    if (qrCodeProcessed) {
                                                      Navigator.pop(context);
                                                      return;
                                                    }

                                                    processBarCode(capture
                                                        .barcodes[0].rawValue);
                                                    Navigator.pop(context);
                                                  })),
                                        ],
                                      ));
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Skannaa QR'),
                          ),
                          unsavedChangesList.isNotEmpty
                              ? const Text('Unsaved changes',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.red))
                              : const Text(''),
                        ])),
                  ),
                  Flexible(
                    flex: 1,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              onPressed: unsavedChangesList.isNotEmpty
                                  ? () {
                                      showDialog(
                                          context: context,
                                          builder: (context) => SimpleDialog(
                                                  title:
                                                      const Text('Varmistus'),
                                                  contentPadding:
                                                      const EdgeInsets.all(
                                                          20.0),
                                                  children: [
                                                    const Text(
                                                        'Haluatko varmasti hylätä muutokset?'),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Peruuta')),
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                unsavedChangesList
                                                                    .clear();
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Hylkää muutokset')),
                                                      ],
                                                    ),
                                                  ]));
                                    }
                                  : null,
                              icon: const Icon(Icons.settings_backup_restore)),
                          IconButton(
                              onPressed: unsavedChangesList.isNotEmpty
                                  ? () {
                                      showDialog(
                                          context: context,
                                          builder: (context) => SimpleDialog(
                                                  title:
                                                      const Text('Varmistus'),
                                                  contentPadding:
                                                      const EdgeInsets.all(
                                                          20.0),
                                                  children: [
                                                    const Text(
                                                        'Haluatko varmasti tallentaa muutokset?'),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Peruuta')),
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              sendUpdatedData();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Tallenna muutokset')),
                                                      ],
                                                    ),
                                                  ]));
                                    }
                                  : null,
                              icon: const Icon(Icons.save)),
                        ]),
                  ),
                ]),
              ),
            ),
            Flexible(
              flex: 10,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var category in deviceCategories)
                      Card(
                        child: ExpandableTheme(
                          data: const ExpandableThemeData(
                              hasIcon: true, iconColor: Colors.white),
                          child: ExpandablePanel(
                            header: Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      toBeginningOfSentenceCase(
                                          category['name']),
                                      style: const TextStyle(fontSize: 25))
                                ],
                              ),
                            ),
                            collapsed: Container(),
                            expanded: Column(
                              children: [
                                for (var device in category['devices'])
                                  Card(
                                    child: Container(
                                      margin: const EdgeInsets.fromLTRB(
                                          10, 0, 10, 0),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              children: [
                                                Text(device['name']),
                                                Text(
                                                    'Stock: ${device['current_stock']} / ${device['total_stock']}'),
                                              ],
                                            ),
                                            ElevatedButton(
                                                onPressed: () {
                                                  if (device['sub_ids'] !=
                                                      null) {
                                                    setupSubIDs(
                                                        device['sub_ids']);
                                                  } else {
                                                    setupSubIDs('');
                                                  }

                                                  var freshSubIDs = [];
                                                  freshSubIDs
                                                      .addAll(changedSubIDs);

                                                  showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                              title: Text(
                                                                  'Muokkaa laitetta - ID: ${device['id']}'),
                                                              contentPadding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      20.0),
                                                              content: Row(
                                                                children: [
                                                                  for (int i =
                                                                          0;
                                                                      i <
                                                                          device[
                                                                              'total_stock'];
                                                                      i++)
                                                                    IconButton(
                                                                      style:
                                                                          ButtonStyle(
                                                                        backgroundColor: WidgetStateProperty.resolveWith<
                                                                            Color>((Set<
                                                                                WidgetState>
                                                                            states) {
                                                                          if (states
                                                                              .contains(WidgetState.pressed)) {
                                                                            return const Color.fromARGB(
                                                                                255,
                                                                                95,
                                                                                22,
                                                                                108);
                                                                          }
                                                                          return changedSubIDs.contains('${device['id']}_${i + 1}')
                                                                              ? Colors.grey
                                                                              : Colors.purple;
                                                                        }),
                                                                      ),
                                                                      onPressed:
                                                                          () {
                                                                        var newSubID =
                                                                            '${device['id']}_${i + 1}';
                                                                        setState(
                                                                            () {
                                                                          changedSubIDs.contains(newSubID)
                                                                              ? {
                                                                                  changedSubIDs.removeWhere((element) => element == newSubID),
                                                                                  stockChange = stockChange + 1,
                                                                                }
                                                                              : {
                                                                                  changedSubIDs.add(newSubID),
                                                                                  stockChange = stockChange - 1,
                                                                                };
                                                                        });
                                                                      },
                                                                      icon: Text(
                                                                          "${i + 1}"),
                                                                    )
                                                                ],
                                                              ),
                                                              //   TextField(
                                                              // controller:
                                                              //     _controller,
                                                              // decoration:
                                                              //     InputDecoration(hintText: 'Uusi numero'),
                                                              // ),
                                                              actions: [
                                                                TextButton(
                                                                  child: const Text(
                                                                      'Valmis'),
                                                                  onPressed:
                                                                      () {
                                                                    if (listEquals(
                                                                        freshSubIDs,
                                                                        changedSubIDs)) {
                                                                      Navigator.pop(
                                                                          context);
                                                                      return;
                                                                    }

                                                                    String
                                                                        preppedSubIDs =
                                                                        '';
                                                                    for (var subID
                                                                        in changedSubIDs) {
                                                                      if (preppedSubIDs
                                                                          .isNotEmpty) {
                                                                        preppedSubIDs =
                                                                            '$preppedSubIDs ';
                                                                      }
                                                                      preppedSubIDs =
                                                                          preppedSubIDs +
                                                                              subID;
                                                                    }

                                                                    if (preppedSubIDs
                                                                        .isEmpty) {
                                                                      preppedSubIDs =
                                                                          "empty";
                                                                    }

                                                                    setState(
                                                                        () {
                                                                      for (var unsavedChange
                                                                          in unsavedChangesList) {
                                                                        if (unsavedChange['id'] ==
                                                                            device['id']) {
                                                                          unsavedChange['current_stock'] +=
                                                                              stockChange;
                                                                          unsavedChange['sub_ids'] =
                                                                              preppedSubIDs;
                                                                        }
                                                                      }
                                                                      unsavedChangesList
                                                                          .add({
                                                                        'id': device[
                                                                            'id'],
                                                                        'current_stock':
                                                                            device['current_stock'] +
                                                                                stockChange,
                                                                        'sub_ids':
                                                                            preppedSubIDs
                                                                      });
                                                                    });

                                                                    _controller
                                                                        .clear();
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                )
                                                              ]));
                                                },
                                                child: const Icon(Icons.edit)),
                                          ]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          ]),
        ),
      );
}
