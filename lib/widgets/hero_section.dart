import 'package:flutter/material.dart';

class HeroSection extends StatefulWidget {
  final String title;
  const HeroSection({
    super.key,
    required this.title
  });
  @override
  State<StatefulWidget> createState() => _HeroSectionState(title);
}

class _HeroSectionState extends State<HeroSection> {
  final String title;
  late bool isFavorited;

  _HeroSectionState(this.title);

  @override
  void initState() {
    super.initState();
    isFavorited = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/car.png'),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => isFavorited = !isFavorited),
              child: Icon(
                Icons.star,
                color: isFavorited ? Colors.amber : Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}