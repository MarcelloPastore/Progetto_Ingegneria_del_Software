import 'package:flutter/material.dart';

class AppSectionTitle extends StatelessWidget {
  final String text;

  const AppSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF44434B),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
