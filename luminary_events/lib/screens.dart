import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart";
import 'CalendarSivu.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.useRouter = false});

  final bool useRouter;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Etusivu")),
        backgroundColor: Colors.indigo,
        body: ListView(
          padding: const EdgeInsets.all(16)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom),
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: TextField(
                decoration: InputDecoration(hintText: "Test Text Field 1"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (useRouter) {
                    context.go("/home/detail");
                  } else {
                    pushScreen(
                      context,
                      settings: const RouteSettings(name: "/home"),
                      screen: const CalendarSivu(),
                      pageTransitionAnimation:
                          PageTransitionAnimation.scaleRotate,
                    );
                  }
                },
                child: const Text("Go to Second Screen without Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useRootNavigator: true,
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Exit"),
                      ),
                    ),
                  );
                },
                child: const Text("Popup From Bottom ONTOP Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useRootNavigator: false,
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Exit"),
                      ),
                    ),
                  );
                },
                child: const Text("Popup From Bottom UNDER Navbar"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  pushWithNavBar(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) => const ExampleDialog(),
                    ),
                  );
                },
                child: const Text("Push Popup Screen"),
              ),
            ),
          ],
        ),
      );
}

class ExampleDialog extends StatelessWidget {
  const ExampleDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.3,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          color: Colors.amber,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "This is a modal screen",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Return"),
                ),
              ),
            ],
          ),
        ),
      );
}
