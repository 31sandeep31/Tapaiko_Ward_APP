import 'package:flutter/material.dart';

import 'theme.dart';

/// The app mark: a map pin with a ward number badge, drawn in code so it
/// stays crisp at any size and matches the launcher icon.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F57C3), BrandColors.blue],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.location_on_rounded, size: size * 0.72, color: Colors.white),
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: const BoxDecoration(
                  color: BrandColors.crimson,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
