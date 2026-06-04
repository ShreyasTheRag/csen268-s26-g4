import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/horizontal_scroll_list.dart';

class PhotoGallery extends StatelessWidget {
  final List<String>? urls;

  const PhotoGallery({super.key, this.urls});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (urls != null) {
      return HorizontalScrollList(
        height: 100,
        itemCount: urls!.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(urls![index], width: 100, height: 100, fit: BoxFit.cover),
        ),
      );
    }
    return HorizontalScrollList(
      height: 100,
      itemCount: 5,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/car.png', width: 100, height: 100, fit: BoxFit.cover),
      ),
    );
  }
}