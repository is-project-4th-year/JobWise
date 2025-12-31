import 'package:flutter/material.dart';

class LTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? type;
  const LTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.type,
    this.obscure=false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
