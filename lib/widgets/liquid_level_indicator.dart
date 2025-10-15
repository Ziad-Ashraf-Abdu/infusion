// widgets/liquid_level_indicator.dart
import 'package:flutter/material.dart';

class LiquidLevelIndicator extends StatelessWidget {
  final double level; // 0.0 to 100.0

  const LiquidLevelIndicator({
    Key? key,
    required this.level,
  }) : super(key: key);

  Color _getLevelColor() {
    if (level > 50) return const Color(0xFF26A69A); // Teal
    if (level > 20) return const Color(0xFFFFCA28); // Amber
    return const Color(0xFFEF5350); // Red
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 120,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // The animated liquid part
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: (level / 100) * 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // The percentage text
                Center(
                  child: Text(
                    '${level.toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: level > 40 ? Colors.white : Colors.black87,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}