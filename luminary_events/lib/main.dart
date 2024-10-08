import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:luminary_events/interactive_example.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart";
import "varasto_sivu.dart";
import "etu_sivu.dart";

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  initializeDateFormatting()
      .then((_) => runApp(const PersistenBottomNavBarDemo()));
}

class PersistenBottomNavBarDemo extends StatelessWidget {
  const PersistenBottomNavBarDemo({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: "Persistent Bottom Navigation Bar Demo",
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const InteractiveExample());
}

class MinimalExample extends StatelessWidget {
  const MinimalExample({super.key});

  List<PersistentTabConfig> _tabs() => [
        PersistentTabConfig(
          screen: const MainScreen(),
          item: ItemConfig(
            icon: const Icon(Icons.home),
            title: "Etusivu",
          ),
        ),
        PersistentTabConfig(
          screen: const MainScreen(),
          item: ItemConfig(
            icon: const Icon(Icons.calendar_month_outlined),
            title: "Kalenteri",
          ),
        ),
        PersistentTabConfig(
          screen: MainScreen3(),
          item: ItemConfig(
            icon: const Icon(Icons.warehouse),
            title: "Varasto",
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) => PersistentTabView(
        tabs: _tabs(),
        navBarBuilder: (navBarConfig) => Style12BottomNavBar(
          navBarConfig: navBarConfig,
        ),
      );
}
