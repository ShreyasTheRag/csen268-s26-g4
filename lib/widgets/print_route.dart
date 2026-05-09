import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrintRoute extends StatelessWidget {
  const PrintRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Route", style: Theme.of(context).textTheme.labelSmall),
          Text(
            GoRouter.of(context).state.uri.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
