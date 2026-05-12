import 'package:flutter/material.dart';

class HorizontalScrollList extends StatelessWidget {
  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const HorizontalScrollList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: itemBuilder,
      ),
    );
  }
}