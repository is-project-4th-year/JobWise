import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.busy=false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: busy ? const SizedBox(height: 18,width:18,child:CircularProgressIndicator(strokeWidth:2))
                    : Text(label),
      ),
    );
  }
}
