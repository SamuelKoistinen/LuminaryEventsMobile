import "package:luminary_events/screens.dart";
import "package:luminary_events/settings.dart";
import "package:flutter/material.dart";
import "package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart";
import 'CalendarSivu.dart';
import 'VarastoSivu.dart';

class InteractiveExample extends StatefulWidget {
  const InteractiveExample({super.key});

  @override
  State<InteractiveExample> createState() => _InteractiveExampleState();
}

class _InteractiveExampleState extends State<InteractiveExample> {
  final PersistentTabController _controller = PersistentTabController();
  Settings settings = Settings();

  List<PersistentTabConfig> _tabs() => [
        PersistentTabConfig(
          screen: const MainScreen2(),
          item: ItemConfig(
            icon: const Icon(Icons.calendar_month_outlined),
            title: "Kalenteri",
            activeForegroundColor: Colors.teal,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: const MainScreen(),
          item: ItemConfig(
            icon: const Icon(Icons.home),
            title: "Etusivu",
            activeForegroundColor: Colors.blue,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
        PersistentTabConfig(
          screen: MainScreen3(),
          item: ItemConfig(
            icon: const Icon(Icons.warehouse),
            title: "Varasto",
            activeForegroundColor: Colors.teal,
            inactiveForegroundColor: Colors.grey,
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) => PersistentTabView(
        controller: _controller,
        tabs: _tabs(),
        navBarBuilder: (navBarConfig) => settings.navBarBuilder(
          navBarConfig,
          NavBarDecoration(
            color: settings.navBarColor,
            borderRadius: BorderRadius.circular(10),
          ),
          const ItemAnimation(),
          const NeumorphicProperties(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => Dialog(
              child: SettingsView(
                settings: settings,
                onChanged: (newSettings) => setState(() {
                  settings = newSettings;
                }),
              ),
            ),
          ),
          child: const Icon(Icons.settings),
        ),
        backgroundColor: Colors.green,
        margin: settings.margin,
        avoidBottomPadding: settings.avoidBottomPadding,
        handleAndroidBackButtonPress: settings.handleAndroidBackButtonPress,
        resizeToAvoidBottomInset: settings.resizeToAvoidBottomInset,
        stateManagement: settings.stateManagement,
        onWillPop: (context) async {
          await showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Center(
                child: ElevatedButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          );
          return false;
        },
        hideNavigationBar: settings.hideNavBar,
        popAllScreensOnTapOfSelectedTab:
            settings.popAllScreensOnTapOfSelectedTab,
      );
}
