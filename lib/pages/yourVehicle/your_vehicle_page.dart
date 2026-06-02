import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:santa_clara/widgets/add_things_button.dart';
import 'package:santa_clara/widgets/body_text.dart';
import 'package:santa_clara/widgets/hero_section.dart';
import 'package:santa_clara/widgets/photo_gallery.dart';
import 'package:santa_clara/widgets/section_label.dart';
import 'package:santa_clara/widgets/triad.dart';

class YourVehiclePage extends StatelessWidget {
  const YourVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF386625),
        title: const Text('Your Vehicle', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.menu, color: Colors.white),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.account_circle, color: Colors.white))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10.0,
          children: [
            const HeroSection(title: "Vehicle Name"),
            const PhotoGallery(),
            const Triad(keys: ["Aspiration", "Reliability", "Rating"], values: ["Natural", "0 / 5", "1 / 5"]),
            const SectionLabel(
              "Recommended Accessories",
            ),
            BodyText(text: lorem()),
            const SectionLabel(
              "Warnings"
            ),
            const BodyText(text: "None"),
            AddThingsButton(title: "Add Recommended Accessories", action: () async {
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
            )
          ]
        )
      )
    );
  }
}