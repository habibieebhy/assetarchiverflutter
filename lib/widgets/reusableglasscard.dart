import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Material(
          color: Colors.white.withAlpha(26), // Uses the same alpha from our theme
          borderRadius: BorderRadius.circular(24.0),
          child: InkWell(
            onTap: onPressed,
            highlightColor: Colors.white.withAlpha(15),
            splashColor: Colors.white.withAlpha(30),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withAlpha(51),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

