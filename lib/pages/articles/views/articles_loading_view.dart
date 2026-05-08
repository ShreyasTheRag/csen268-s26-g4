import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class ArticlesLoadingView extends StatelessWidget {
  const ArticlesLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const MainDrawer(),
        appBar: AppBar(title: const Text("Articles")),
        body: const Center(child: CircularProgressIndicator()));
  }
}
