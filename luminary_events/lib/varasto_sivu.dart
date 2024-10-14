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

  bool editMode = false;

  final TextEditingController _controller = TextEditingController();

  List listOfChanges = [];
  List busySubIDs = [];

  bool qrCodeProcessed = false;

  String _nameTextFieldValue = '';
  String _priceTextFieldValue = '';
  String _stockTextFieldValue = '';
  String _typeDropdownValue = '';

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
    List updatesToSend = [];

    for (var change in listOfChanges) {
      String processedSubIDList = '';
      for (String subID in change['sub_id_list']) {
        if (processedSubIDList != '') {
          processedSubIDList = '$processedSubIDList ';
        }
        processedSubIDList += subID;
      }
      if (processedSubIDList == '') {
        processedSubIDList = 'empty';
      }
      updatesToSend.add({
        'id': change['id'],
        'current_stock': change['stock_change'],
        'sub_ids': processedSubIDList
      });
    }

    for (var device in updatesToSend) {
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
    listOfChanges.clear();
    getDatabaseInfo();
  }

  updateDevice(id, bool emptyIDs) async {
    String? sendPrice;
    _priceTextFieldValue == ""
        ? sendPrice = null
        : sendPrice = _priceTextFieldValue;

    final response = await http.put(
        Uri.parse("${dotenv.env['BASEURL']}devices/$id"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: emptyIDs
            ? jsonEncode({
                "name": _nameTextFieldValue,
                "price_per_day": sendPrice,
                "total_stock": _stockTextFieldValue,
                "current_stock": _stockTextFieldValue,
                "sub_ids": "empty",
              })
            : jsonEncode(
                {"name": _nameTextFieldValue, "price_per_day": sendPrice}));
    if (response.statusCode == 201) {
    } else {
      throw Exception('Failed to send updated data');
    }
    getDatabaseInfo();
  }

  createDeviceInDB() async {
    final response =
        await http.post(Uri.parse("${dotenv.env['BASEURL']}devices"),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'name': _nameTextFieldValue,
              'description': "jajaja",
              'price_per_day': int.tryParse(_priceTextFieldValue),
              'total_stock': int.tryParse(_stockTextFieldValue),
              'type': _typeDropdownValue
            }));
    if (response.statusCode == 201) {
    } else {
      throw Exception('Failed to send updated data');
    }
    getDatabaseInfo();
  }

  deleteDeviceFromDB(id) async {
    final response = await http.delete(
        Uri.parse("${dotenv.env['BASEURL']}devices/$id"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        });
    if (response.statusCode == 204) {
    } else {
      throw Exception('Failed to delete');
    }
    getDatabaseInfo();
  }

  setupSubIDs(String? dbSubIDs) {
    busySubIDs.clear();
    if (dbSubIDs == null) {
      return;
    }
    dbSubIDs.split(' ').forEach((element) {
      if (element != '') busySubIDs.add(element);
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

    var device;
    final response = await http
        .get(Uri.parse("${dotenv.env['BASEURL']}devices/${barcodeSplit[0]}"));
    if (response.statusCode == 200) {
      device = json.decode(response.body);
    } else {
      throw Exception('Failed to load database info');
    }

    setupSubIDs(device['sub_ids']);

    bool changeToDeviceAlreadyExists = false;
    bool changeToSubIDAlreadyExists = false;
    int deviceIndex = -1;
    int subIDIndex = -1;
    bool subIDReturned = false;
    for (var device in listOfChanges.indexed) {
      if (device.$2['id'] == barcodeSplit[0]) {
        changeToDeviceAlreadyExists = true;
        deviceIndex = device.$1;
        for (var change in device.$2['individual_changes'].indexed) {
          if (change.$2['sub_id'] == barcode) {
            changeToSubIDAlreadyExists = true;
            subIDIndex = change.$1;
            subIDReturned = change.$2['returned'];
          }
        }
      }
    }

    int stockChange = 0;
    var newChange;

    if (changeToSubIDAlreadyExists == false) {
      if (busySubIDs.contains(barcode)) {
        stockChange += 1;
        subIDReturned = true;
        busySubIDs.remove(barcode);
      } else {
        stockChange -= 1;
        busySubIDs.add(barcode);
      }

      List subIdList = [];
      subIdList.addAll(busySubIDs);
      Map<String, dynamic> oneChange = {
            'sub_id': barcode,
            'returned': subIDReturned
          },
          newChange = {
            'id': device['id'],
            'name': device['name'],
            'individual_changes': [oneChange],
            'stock_change': device['current_stock'] + stockChange,
            'sub_id_list': subIdList
          };

      if (changeToSubIDAlreadyExists == false) {
        if (changeToDeviceAlreadyExists == false) {
          listOfChanges.add(newChange);
        } else if (changeToDeviceAlreadyExists == true) {
          listOfChanges
              .elementAt(deviceIndex)['individual_changes']
              .add(oneChange);
          listOfChanges.elementAt(deviceIndex)['stock_change'] += stockChange;
          if (listOfChanges
              .elementAt(deviceIndex)['sub_id_list']
              .contains(barcode)) {
            listOfChanges.elementAt(deviceIndex)['sub_id_list'].remove(barcode);
          } else {
            listOfChanges.elementAt(deviceIndex)['sub_id_list'].add(barcode);
          }
        }
      } else if (changeToSubIDAlreadyExists == true) {
        listOfChanges
            .elementAt(deviceIndex)['individual_changes']
            .removeWhere((element) => element['sub_id'] == barcode);

        if (subIDReturned == true) {
          if (!busySubIDs.contains(barcode)) {
            busySubIDs.add(barcode);
          }
        } else if (subIDReturned == false) {
          if (busySubIDs.contains(barcode)) {
            busySubIDs.remove(barcode);
          }
        }

        if (listOfChanges
            .elementAt(deviceIndex)['individual_changes']
            .isEmpty) {
          listOfChanges.removeAt(deviceIndex);
        } else {
          if (subIDReturned == true) {
            listOfChanges.elementAt(deviceIndex)['stock_change'] -= 1;
            if (!busySubIDs.contains(barcode)) {
              busySubIDs.add(barcode);
            }
            if (!listOfChanges
                .elementAt(deviceIndex)['sub_id_list']
                .contains(barcode)) {
              listOfChanges.elementAt(deviceIndex)['sub_id_list'].add(barcode);
            }
          } else if (subIDReturned == false) {
            listOfChanges.elementAt(deviceIndex)['stock_change'] += 1;

            listOfChanges.elementAt(deviceIndex)['sub_id_list'].remove(barcode);
            if (busySubIDs.contains(barcode)) {
              busySubIDs.remove(barcode);
            }
          }
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Varasto"),
          actions: [
            const Text('Muokkaustila'),
            Switch(
              value: editMode,
              onChanged: (value) {
                setState(
                  () {
                    editMode = value;
                  },
                );
              },
            ),
            TextButton.icon(
                label: const Text('Uusi laite'),
                onPressed: () {
                  _typeDropdownValue = '';
                  _nameTextFieldValue = '';
                  _priceTextFieldValue = '';
                  _stockTextFieldValue = '';
                  showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return SimpleDialog(
                                title: const Text('Lisää laite'),
                                contentPadding: const EdgeInsets.all(20.0),
                                children: [
                                  TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _nameTextFieldValue = value;
                                      });
                                    },
                                  ),
                                  const Text('Nimi'),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _priceTextFieldValue = value;
                                      });
                                    },
                                  ),
                                  const Text('Vuokrahinta'),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _stockTextFieldValue = value;
                                      });
                                    },
                                  ),
                                  const Text('Kappaletta varastossa'),
                                  DropdownButton(
                                    isExpanded: true,
                                    hint: Text(_typeDropdownValue),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'kokoääni',
                                          child: Text('Kokoääni')),
                                      DropdownMenuItem(
                                          value: 'sub', child: Text('Sub')),
                                      DropdownMenuItem(
                                          value: 'dj', child: Text('DJ')),
                                      DropdownMenuItem(
                                          value: 'lavatekniikka',
                                          child: Text('Lavatekniikka')),
                                    ],
                                    onChanged: (value) {
                                      if (value is String) {
                                        setState(() {
                                          _typeDropdownValue = value;
                                        });
                                      }
                                    },
                                  ),
                                  const Text('Tyyppi'),
                                  Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Peruuta')),
                                        ElevatedButton(
                                            onPressed: () {
                                              createDeviceInDB();
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Luo laite')),
                                      ],
                                    ),
                                  ),
                                ]);
                          },
                        );
                      });
                },
                icon: const Icon(Icons.add))
          ],
        ),
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
                    flex: 3,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                          listOfChanges.isNotEmpty
                              ? const Text('Tallentamattomia muutoksia',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
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
                              onPressed: listOfChanges.isNotEmpty
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
                                                                listOfChanges
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
                              onPressed: listOfChanges.isNotEmpty
                                  ? () {
                                      showDialog(
                                          context: context,
                                          builder:
                                              (context) => SimpleDialog(
                                                      title: const Text(
                                                          'Varmistus'),
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              20.0),
                                                      children: [
                                                        const Text(
                                                            'Haluatko varmasti tallentaa muutokset?'),
                                                        const Text(
                                                            'Lista muutoksista:'),
                                                        SingleChildScrollView(
                                                          child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                for (var change
                                                                    in listOfChanges)
                                                                  for (var element
                                                                      in change[
                                                                          'individual_changes'])
                                                                    element['returned']
                                                                        ? Text(
                                                                            "${change['name']}: +${element['sub_id']}",
                                                                            style:
                                                                                const TextStyle(color: Colors.green),
                                                                          )
                                                                        : Text(
                                                                            "${change['name']}: -${element['sub_id']}",
                                                                            style:
                                                                                const TextStyle(color: Colors.red),
                                                                          )
                                                              ]),
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
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
                                                    'Varastossa: ${device['current_stock']} / ${device['total_stock']}'),
                                              ],
                                            ),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _nameTextFieldValue = "";
                                                  _priceTextFieldValue = "";
                                                  _stockTextFieldValue = "";

                                                  if (device['sub_ids'] !=
                                                      null) {
                                                    setupSubIDs(
                                                        device['sub_ids']);
                                                  } else {
                                                    setupSubIDs('');
                                                  }

                                                  var freshSubIDs = [];
                                                  freshSubIDs
                                                      .addAll(busySubIDs);

                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                              title: editMode
                                                                  ? Text(
                                                                      'Muokkaa laitetta - ID: ${device['id']}')
                                                                  : Text(
                                                                      'Muokkaa varastoa - ID: ${device['id']}'),
                                                              contentPadding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      20.0),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  editMode
                                                                      ? Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            const Text('Huom: Jos muokkaat varastomäärää, tämä palauttaa sub-ID:t! Korjaa manuaalisesti jälkeenpäin'),
                                                                            TextField(
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  _nameTextFieldValue = value;
                                                                                });
                                                                              },
                                                                              decoration: InputDecoration(hintText: device['name']),
                                                                            ),
                                                                            const Text('Nimi'),
                                                                            TextField(
                                                                              keyboardType: TextInputType.number,
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  _priceTextFieldValue = value;
                                                                                });
                                                                              },
                                                                              decoration: InputDecoration(hintText: "${device['price_per_day']}"),
                                                                            ),
                                                                            const Text('Vuokrahinta'),
                                                                            TextField(
                                                                              keyboardType: TextInputType.number,
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  _stockTextFieldValue = value;
                                                                                });
                                                                              },
                                                                              decoration: InputDecoration(hintText: "${device['total_stock']}"),
                                                                            ),
                                                                            const Text('Kokonaismäärä varastossa'),
                                                                          ],
                                                                        )
                                                                      : Wrap(
                                                                          children: [
                                                                            for (int loopDevice = 0;
                                                                                loopDevice < device['total_stock'];
                                                                                loopDevice++)
                                                                              IconButton(
                                                                                style: ButtonStyle(
                                                                                  backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                                                                    if (states.contains(WidgetState.pressed)) {
                                                                                      return const Color.fromARGB(255, 95, 22, 108);
                                                                                    }
                                                                                    bool exists = false;
                                                                                    bool returned = false;
                                                                                    for (var change in listOfChanges) {
                                                                                      if (change['id'] == device['id']) {
                                                                                        for (int a = 0; a <= change['individual_changes'].length - 1; a++) {
                                                                                          List individualChanges = change['individual_changes'];
                                                                                          if (individualChanges.elementAt(a)['sub_id'] == '${device['id']}_${loopDevice + 1}') {
                                                                                            exists = true;
                                                                                            if (individualChanges.elementAt(a)['returned'] == true) {
                                                                                              returned = true;
                                                                                            }
                                                                                          }
                                                                                        }
                                                                                      }
                                                                                    }

                                                                                    if (exists == true) {
                                                                                      return returned ? Colors.purple : Colors.grey;
                                                                                    } else {
                                                                                      return busySubIDs.contains('${device['id']}_${loopDevice + 1}') ? Colors.grey : Colors.purple;
                                                                                    }
                                                                                  }),
                                                                                ),
                                                                                onPressed: () {
                                                                                  var newSubID = '${device['id']}_${loopDevice + 1}';
                                                                                  setState(() {
                                                                                    Map<String, dynamic> newChange;

                                                                                    bool changeWithIDExists = false;
                                                                                    bool individualChangeExists = false;
                                                                                    bool individualReturned = false;
                                                                                    for (var change in listOfChanges) {
                                                                                      if (change['id'] == device['id']) {
                                                                                        changeWithIDExists = true;
                                                                                        for (int a = 0; a <= change['individual_changes'].length - 1; a++) {
                                                                                          List individualChanges = change['individual_changes'];
                                                                                          if (individualChanges.elementAt(a)['sub_id'] == '${device['id']}_${loopDevice + 1}') {
                                                                                            individualChangeExists = true;
                                                                                            if (individualChanges.elementAt(a)['returned'] == true) {
                                                                                              individualReturned = true;
                                                                                            }
                                                                                          }
                                                                                        }
                                                                                      }
                                                                                    }

                                                                                    //first time for device
                                                                                    if (individualChangeExists == false) {
                                                                                      int stockChange = 0;
                                                                                      bool returned = false;

                                                                                      if (busySubIDs.contains(newSubID)) {
                                                                                        stockChange += 1;
                                                                                        returned = true;
                                                                                        busySubIDs.remove(newSubID);
                                                                                      } else {
                                                                                        stockChange -= 1;
                                                                                        busySubIDs.add(newSubID);
                                                                                      }

                                                                                      List subIdList = [];
                                                                                      subIdList.addAll(busySubIDs);
                                                                                      Map<String, dynamic> oneChange = {
                                                                                            'sub_id': newSubID,
                                                                                            'returned': returned
                                                                                          },
                                                                                          newChange = {
                                                                                            'id': device['id'],
                                                                                            'name': device['name'],
                                                                                            'individual_changes': [oneChange],
                                                                                            'stock_change': device['current_stock'] + stockChange,
                                                                                            'sub_id_list': subIdList
                                                                                          };

                                                                                      if (changeWithIDExists == false) {
                                                                                        listOfChanges.add(newChange);
                                                                                      } else if (changeWithIDExists == true) {
                                                                                        int index = listOfChanges.indexWhere((element) => element['id'] == device['id']);
                                                                                        listOfChanges.elementAt(index)['individual_changes'].add(oneChange);
                                                                                        listOfChanges.elementAt(index)['stock_change'] += stockChange;
                                                                                        if (listOfChanges.elementAt(index)['sub_id_list'].contains(newSubID)) {
                                                                                          listOfChanges.elementAt(index)['sub_id_list'].remove(newSubID);
                                                                                        } else {
                                                                                          listOfChanges.elementAt(index)['sub_id_list'].add(newSubID);
                                                                                        }
                                                                                      }
                                                                                    } else if (individualChangeExists == true) {
                                                                                      int index = listOfChanges.indexWhere((element) => element['id'] == device['id']);
                                                                                      listOfChanges.elementAt(index)['individual_changes'].removeWhere((element) => element['sub_id'] == newSubID);

                                                                                      if (individualReturned == true) {
                                                                                        if (!busySubIDs.contains(newSubID)) {
                                                                                          busySubIDs.add(newSubID);
                                                                                        }
                                                                                      } else if (individualReturned == false) {
                                                                                        if (busySubIDs.contains(newSubID)) {
                                                                                          busySubIDs.remove(newSubID);
                                                                                        }
                                                                                      }

                                                                                      if (listOfChanges.elementAt(index)['individual_changes'].isEmpty) {
                                                                                        listOfChanges.removeAt(index);
                                                                                      } else {
                                                                                        if (individualReturned == true) {
                                                                                          listOfChanges.elementAt(index)['stock_change'] -= 1;

                                                                                          if (!busySubIDs.contains(newSubID)) {
                                                                                            busySubIDs.add(newSubID);
                                                                                          }
                                                                                          if (!listOfChanges.elementAt(index)['sub_id_list'].contains(newSubID)) {
                                                                                            listOfChanges.elementAt(index)['sub_id_list'].add(newSubID);
                                                                                          }
                                                                                        } else if (individualReturned == false) {
                                                                                          listOfChanges.elementAt(index)['stock_change'] += 1;

                                                                                          listOfChanges.elementAt(index)['sub_id_list'].remove(newSubID);
                                                                                          if (busySubIDs.contains(newSubID)) {
                                                                                            busySubIDs.remove(newSubID);
                                                                                          }
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  });
                                                                                },
                                                                                icon: Text("${loopDevice + 1}"),
                                                                              )
                                                                          ],
                                                                        ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                editMode
                                                                    ? TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                          return;
                                                                        },
                                                                        child: const Text(
                                                                            'Peruuta'),
                                                                      )
                                                                    : const SizedBox(),
                                                                editMode
                                                                    ? TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          showDialog(
                                                                              context: context,
                                                                              builder: (context) => SimpleDialog(title: const Text('Varmistus'), contentPadding: const EdgeInsets.all(20.0), children: [
                                                                                    const Text('Haluatko varmasti poistaa laitteen?'),
                                                                                    const SizedBox(
                                                                                      height: 15,
                                                                                    ),
                                                                                    const Text('Tätä ei voi perua!'),
                                                                                    const SizedBox(
                                                                                      height: 15,
                                                                                    ),
                                                                                    Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        ElevatedButton(
                                                                                            onPressed: () {
                                                                                              Navigator.pop(context);
                                                                                            },
                                                                                            child: const Text('Peruuta')),
                                                                                        ElevatedButton(
                                                                                            onPressed: () {
                                                                                              setState(() {
                                                                                                deleteDeviceFromDB(device['id']);
                                                                                              });
                                                                                              Navigator.of(context)
                                                                                                ..pop()
                                                                                                ..pop();
                                                                                            },
                                                                                            child: const Text('Poista laite')),
                                                                                      ],
                                                                                    ),
                                                                                  ]));
                                                                        },
                                                                        child: const Text(
                                                                            'Poista laite'),
                                                                      )
                                                                    : const SizedBox(),
                                                                editMode
                                                                    ? TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          if (_nameTextFieldValue == "" &&
                                                                              _priceTextFieldValue == "" &&
                                                                              _stockTextFieldValue == "") {
                                                                            Navigator.pop(context);
                                                                            return;
                                                                          } else {
                                                                            showDialog(
                                                                                context: context,
                                                                                builder: (context) => SimpleDialog(title: const Text('Varmistus'), contentPadding: const EdgeInsets.all(20.0), children: [
                                                                                      const Text('Haluatko varmasti päivittää laitteen?'),
                                                                                      const SizedBox(
                                                                                        height: 15,
                                                                                      ),
                                                                                      const Text('Tätä ei voi perua!'),
                                                                                      const SizedBox(
                                                                                        height: 15,
                                                                                      ),
                                                                                      Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                                        children: [
                                                                                          ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.pop(context);
                                                                                              },
                                                                                              child: const Text('Peruuta')),
                                                                                          ElevatedButton(
                                                                                              onPressed: () {
                                                                                                if (device['total_stock'] != int.tryParse(_stockTextFieldValue) && _stockTextFieldValue != "") {
                                                                                                  updateDevice(device['id'], true);
                                                                                                } else {
                                                                                                  updateDevice(device['id'], false);
                                                                                                }
                                                                                                Navigator.of(context)
                                                                                                  ..pop()
                                                                                                  ..pop();
                                                                                              },
                                                                                              child: const Text('Päivitä laite')),
                                                                                        ],
                                                                                      ),
                                                                                    ]));
                                                                          }
                                                                        },
                                                                        child: const Text(
                                                                            'Valmis'))
                                                                    : TextButton(
                                                                        child: const Text(
                                                                            'Valmis'),
                                                                        onPressed:
                                                                            () {
                                                                          if (listEquals(
                                                                              freshSubIDs,
                                                                              busySubIDs)) {
                                                                            Navigator.pop(context);
                                                                            return;
                                                                          }

                                                                          setState(
                                                                              () {});

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
                    const SizedBox(
                      height: 75,
                    )
                  ],
                ),
              ),
            )
          ]),
        ),
      );
}
