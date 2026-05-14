import 'package:flutter/material.dart';

class Triad extends StatelessWidget {
  final List<String?> keys, values;
  final VoidCallback? onFirstTap, onSecondTap, onThirdTap;

  const Triad(
      {required this.keys,
      required this.values,
      this.onFirstTap,
      this.onSecondTap,
      this.onThirdTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(keys[0]!, values[0]!, onFirstTap),
          _buildVerticalDivider(),
          _buildStatItem(keys[1]!, values[1]!, onSecondTap),
          _buildVerticalDivider(),
          _buildStatItem(keys[2]!, values[2]!, onThirdTap),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback? action) {
    return InkWell(
      onTap: action,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ],
      )
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.black26);
  }
}