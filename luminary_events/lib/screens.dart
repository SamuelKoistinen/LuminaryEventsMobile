import "package:flutter/material.dart";

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
