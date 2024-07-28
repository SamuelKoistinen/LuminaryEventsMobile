import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.useRouter = false});

  final bool useRouter;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Etusivu testi ukko")),
        backgroundColor: Color.fromARGB(255, 238, 158, 211),
        body: ListView(
          padding: const EdgeInsets.all(16)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom),
          children: <Widget>[],
        ),
      );
}
