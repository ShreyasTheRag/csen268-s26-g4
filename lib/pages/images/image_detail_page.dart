// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/print_route.dart';

class ImageDetailPage extends StatelessWidget {
  const ImageDetailPage({super.key, this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Image Detail"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              imageUrl == null ? const Text("Error") : Image.network(imageUrl!),
              const SizedBox(height: 20),
              const PrintRoute(),
            ]),
          ),
        ));
  }
}
