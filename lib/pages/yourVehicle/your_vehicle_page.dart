import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:santa_clara/pages/generic/generic_page.dart';
import 'package:santa_clara/widgets/triad.dart';

class YourVehiclePage extends StatelessWidget {
  const YourVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    double containerSide = 80.0;
    Container c = Container(
      width: containerSide,
      height: containerSide,
      color: Theme.of(context).colorScheme.primaryContainer
    );
    return GenericPage(
      title: "Your Vehicle",
      body: Padding(
        padding: const EdgeInsetsGeometry.all(40.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10.0,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              const Text(
                "Vehicle Name",
                style: TextStyle(
                  fontWeight: FontWeight.bold
                )
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 5.0,
                  children: [
                    c,
                    c,
                    c,
                    c,
                  ]
                )
              ),
              /*
              const Row(
                spacing: 3.0,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text("Aspiration",
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                        Text("<aspiration>")
                      ]
                    )
                  ),
                  Center(
                    child: Column(
                      children: [
                        Text("Reliability",
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                        Text("0 / 5")
                      ]
                    )
                  ),
                  Center(
                    child: Column(
                      children: [
                        Text("Rating",
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                        Text("0 / 5")
                      ]
                    )
                  )
                ]
              ),*/
              const Triad(keys: ["Aspiration", "Reliability", "Rating"], values: ["Natural", "0 / 5", "1 / 5"], width: 150, height: 60),
              const Text(
                "Recommended Accessories",
                style: TextStyle(
                  fontWeight: FontWeight.bold
                )
              ),
              Text(lorem()),
              const Text(
                "Warnings",
                style: TextStyle(
                  fontWeight: FontWeight.bold
                )
              ),
              const Text("None"),
              FilledButton(
                onPressed: () async {
                  await showDialog<bool>(context: context, builder: (context) {
                    return AlertDialog(
                      title: const Text("Add recommended accessories?"),
                      actions: [
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("No")
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Yes")
                        )
                      ],
                    );
                  });
                }, 
                child: const Text("Add Recommended Accessories")
              )
            ]
          )
        )
      )
    );
  }
}