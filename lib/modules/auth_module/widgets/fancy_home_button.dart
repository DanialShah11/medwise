import 'package:flutter/material.dart';

class FancyHomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const FancyHomeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: color != null
                ? [color!.withOpacity(0.8), color!]
                : [Colors.blueAccent, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(icon, size: 38, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
