import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class ImagesPage extends StatelessWidget {
  const ImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Images"),
        ),
        drawer: MainDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "Click on the image to see the detail page without the navigation bar on the bottom. "),
              const SizedBox(height: 20),
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                itemCount: 3,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      context.goNamed("imageDetail", queryParameters: {
                        'imageUrl':
                            'https://picsum.photos/id/${index + 610}/300/300'
                      });
                    },
                    leading: Image.network(
                      "https://picsum.photos/id/${index + 610}/100",
                    ),
                    title: Text("Image $index"),
                  );
                },
              ),
            ],
          ),
        ));
  }
}
