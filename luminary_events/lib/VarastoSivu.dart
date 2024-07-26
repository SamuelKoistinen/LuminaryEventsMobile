import 'package:expandable/expandable.dart';
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
                          unsavedChanges
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
                                        onPressed: unsavedChanges
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
                                                                          unsavedChanges =
                                                                              false;
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
                                        onPressed: unsavedChanges
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
                                                                        setState(
                                                                            () {
                                                                          unsavedChanges =
                                                                              false;
                                                                        });
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
                child: Column(
                  children: [
                    Card(
                      child: Container(
                          child: ExpandableTheme(
                              data: ExpandableThemeData(hasIcon: false),
                              child: ExpandablePanel(
                                  header: Text('Header'),
                                  collapsed:
                                      Container(child: Text('collapsed')),
                                  expanded:
                                      Container(child: Text('expanded'))))),
                    )
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 4,
              child: Container(color: Colors.orange),
            ),
          ]),
        ),
      );
}
