import 'package:flutter/material.dart';

class BodyText extends StatelessWidget {
  final String text;
  static const TextStyle style = TextStyle(color: Colors.black87, fontSize: 14, height: 1.4);

  const BodyText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Text(
      text,
      style: style
    );
  }
}