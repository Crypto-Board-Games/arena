import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StoneWidget extends StatelessWidget {
  final bool isBlack;
  final bool isLastMove;
  final double size;

  const StoneWidget({
    super.key,
    required this.isBlack,
    this.isLastMove = false,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBlack ? AppTheme.blackStone : AppTheme.whiteStone,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        gradient: isBlack
            ? RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  Colors.grey.shade800,
                  AppTheme.blackStone,
                ],
              )
            : const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Colors.white, Color(0xFFE8E8E8)],
              ),
        border: isLastMove
            ? Border.all(
                color: Colors.red,
                width: 2,
              )
            : null,
      ),
    );
  }
}
