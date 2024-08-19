import "package:flutter/material.dart";
import 'env.dart';


class MainScreen3 extends StatelessWidget {
  const MainScreen3({super.key});
  
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Varasto")),
        backgroundColor: Colors.deepOrangeAccent,
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              debugPrint(Env.passwordkey);
            },
            child: Text(Env.apikey),
          ),
        ),
      );
}