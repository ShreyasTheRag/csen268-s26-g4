import 'package:flutter/material.dart';

class Triad extends StatelessWidget {
  final List<String?> keys, values;
  final double width, height;
  final VoidCallback? onFirstTap, onSecondTap, onThirdTap;
  static const TextStyle _bold = TextStyle(fontWeight: FontWeight.bold);

  const Triad(
      {required this.keys,
      required this.values,
      required this.width,
      required this.height,
      this.onFirstTap,
      this.onSecondTap,
      this.onThirdTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenOfRow = [
      SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onFirstTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Text(keys[0]!, style: _bold), Text(values[0]!)],
          ),
        )
      ),
      Container(
        width: 2,
        height: height - 10.0,
        color: Theme.of(context).colorScheme.primary
      ),
      SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onSecondTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Text(keys[1]!, style: _bold), Text(values[1]!)],
          ),
        )
      ),
      Container(
        width: 2,
        height: height - 10.0,
        color: Theme.of(context).colorScheme.primary
      ),
      SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onThirdTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Text(keys[2]!, style: _bold), Text(values[2]!)],
          ),
        )
      ),
    ];
    return Container(
      width: (3.5 * width) + 4,
      height: height,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10.0,
        children: childrenOfRow
      )
    );
  }
}