import 'package:flutter/material.dart';
import 'package:santa_clara/models/article.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class ArticlesDetailView extends StatelessWidget {
  final void Function() close;
  final Article article;
  const ArticlesDetailView(
      {super.key, required this.article, required this.close});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const MainDrawer(),
        appBar: AppBar(
          title: const Text("Articles"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: close,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Title", style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 3),
                Text(article.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text("Author", style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 3),
                Text(article.author,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(article.text,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ));
  }
}
