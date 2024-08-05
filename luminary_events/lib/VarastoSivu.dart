import 'dart:convert';

import 'package:expandable/expandable.dart';
import 'package:http/http.dart' as http;
import "package:flutter/material.dart";
import 'env.dart';

/*
Center(
          child: ElevatedButton(
            onPressed: () {
              debugPrint(Env.passwordkey);
            },
            child: Text(Env.apikey),
          ),
        ),
*/

class MainScreen3 extends StatefulWidget {
  MainScreen3({super.key});

  @override
  State<MainScreen3> createState() => _MainScreen3State();
}

class _MainScreen3State extends State<MainScreen3> {
  bool editModeSwitch = false;
  bool unsavedChanges = false;

  final TextEditingController _controller = TextEditingController();

  List unsavedChangesList = [];

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

  getDatabaseInfo() async {
    for (var category in deviceCategories) {
      category['devices'].clear();
    }
    final response =
        await http.get(Uri.parse("https://mekelektro.com/devices"));
    if (response.statusCode == 200) {
      final List parsedList = json.decode(response.body);
      for (var device in parsedList) {
        for (var category in deviceCategories) {
          if (device['type'] == category['name']) {
            category['devices'].add(device);
            print("device added");
          }
        }
      }
      print(deviceCategories);
      setState(() => {});
    } else {
      throw Exception('Failed to load database info');
    }
  }

  sendUpdatedData() async {
    for (var device in unsavedChangesList) {
      print(device);
      print(device['id']);
      print(device['current_stock']);
      final response = await http.put(
        Uri.parse("https://mekelektro.com/devices/${device['id']}"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'current_stock': device['current_stock'],
        }),
      );
      if (response.statusCode == 201) {
      } else {
        print(response.body);
        print(response.statusCode);
        throw Exception('Failed to send updated data');
      }
    }
    unsavedChangesList.clear();
    setState(() {
      getDatabaseInfo();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Varasto")),
        backgroundColor: Colors.deepOrangeAccent,
        body: Center(
          child: Column(children: [
            Flexible(
              flex: 1,
              child: Container(
                color: Colors.cyan,
                child: Row(children: [
                  Flexible(
                    flex: 3,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Row(children: [
                          Text('Edit mode', style: TextStyle(fontSize: 20)),
                          Switch(
                              value: editModeSwitch,
                              onChanged: (value) {
                                setState(() {
                                  editModeSwitch = value;
                                  unsavedChanges = value;
                                });
                              }),
                          unsavedChangesList.isNotEmpty
                              ? Text('Unsaved changes',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.red))
                              : Text(''),
                        ])),
                  ),
                  Flexible(
                    flex: 1,
                    child: Container(
                        color: Colors.green,
                        child: Row(
                            children: editModeSwitch
                                ? [
                                    IconButton(
                                        onPressed: unsavedChangesList.isNotEmpty
                                            ? () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        SimpleDialog(
                                                            title: Text(
                                                                'Varmistus'),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(20.0),
                                                            children: [
                                                              Text(
                                                                  'Haluatko varmasti hylätä muutokset?'),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Text(
                                                                          'Peruuta')),
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          unsavedChangesList
                                                                              .clear();
                                                                        });
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Text(
                                                                          'Hylkää muutokset')),
                                                                ],
                                                              ),
                                                            ]));
                                              }
                                            : null,
                                        icon: Icon(
                                            Icons.settings_backup_restore)),
                                    IconButton(
                                        onPressed: unsavedChangesList.isNotEmpty
                                            ? () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        SimpleDialog(
                                                            title: Text(
                                                                'Varmistus'),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(20.0),
                                                            children: [
                                                              Text(
                                                                  'Haluatko varmasti tallentaa muutokset?'),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Text(
                                                                          'Peruuta')),
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        sendUpdatedData();
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Text(
                                                                          'Tallenna muutokset')),
                                                                ],
                                                              ),
                                                            ]));
                                              }
                                            : null,
                                        icon: Icon(Icons.save)),
                                  ]
                                : [])),
                  ),
                ]),
              ),
            ),
            Flexible(
              flex: 10,
              child: Container(
                color: Colors.indigo,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var category in deviceCategories)
                        Card(
                          child: Container(
                            child: ExpandableTheme(
                              data: ExpandableThemeData(hasIcon: false),
                              child: ExpandablePanel(
                                header: Text(category['name']),
                                collapsed: Container(
                                  child: Text('collapsed'),
                                ),
                                expanded: Column(
                                  children: [
                                    for (var device in category['devices'])
                                      Card(
                                        child: Container(
                                          child: ExpandableTheme(
                                            data: ExpandableThemeData(
                                                hasIcon: false),
                                            child: ExpandablePanel(
                                              header: Text(device['name']),
                                              collapsed: Container(
                                                child: Text('collapsed'),
                                              ),
                                              expanded: Row(children: [
                                                Column(
                                                  children: [
                                                    Text('Type: ' +
                                                        device['type']),
                                                    Text('Description: ' +
                                                        device['description']),
                                                    Text('Stock: ' +
                                                        device['current_stock']
                                                            .toString() +
                                                        ' / ' +
                                                        device['total_stock']
                                                            .toString()),
                                                  ],
                                                ),
                                                ElevatedButton(
                                                    onPressed: editModeSwitch
                                                        ? () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) =>
                                                                    AlertDialog(
                                                                        title: Text(
                                                                            'Muokkaa laitetta'),
                                                                        contentPadding: const EdgeInsets
                                                                            .all(
                                                                            20.0),
                                                                        content:
                                                                            TextField(
                                                                          controller:
                                                                              _controller,
                                                                          decoration:
                                                                              InputDecoration(hintText: 'Uusi numero'),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            child:
                                                                                Text('Submit'),
                                                                            onPressed:
                                                                                () {
                                                                              setState(() {
                                                                                unsavedChangesList.add({
                                                                                  'id': device['id'],
                                                                                  'current_stock': _controller.text
                                                                                });
                                                                              });

                                                                              _controller.clear();
                                                                              Navigator.pop(context);
                                                                            },
                                                                          )
                                                                        ]));
                                                          }
                                                        : null,
                                                    child: Icon(Icons.edit)),
                                              ]),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 4,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      getDatabaseInfo();
                    },
                    child: Text('Hae tietokanta'),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        print(unsavedChangesList);
                      },
                      child: Text('show text'))
                ],
              ),
            ),
          ]),
        ),
      );
}
