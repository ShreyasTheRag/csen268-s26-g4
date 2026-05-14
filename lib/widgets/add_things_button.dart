import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/full_width_button.dart';

class AddThingsButton extends StatelessWidget {
  final String title;
  final VoidCallback action;

  const AddThingsButton({super.key, required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FullWidthButton(
      text: title,
      onPressed: action,
      color: const Color(0xFF558B2F),
    );
  }
}