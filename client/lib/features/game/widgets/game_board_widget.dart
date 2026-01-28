import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'stone_widget.dart';

class GameBoardWidget extends StatelessWidget {
  final List<List<int>> board;
  final bool isMyTurn;
  final Function(int x, int y) onCellTap;
  final int? lastMoveX;
  final int? lastMoveY;

  const GameBoardWidget({
    super.key,
    required this.board,
    required this.isMyTurn,
    required this.onCellTap,
    this.lastMoveX,
    this.lastMoveY,
  });

  static const int boardSize = 15;
  static const List<List<int>> starPoints = [
    [3, 3], [3, 7], [3, 11],
    [7, 3], [7, 7], [7, 11],
    [11, 3], [11, 7], [11, 11],
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.boardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / boardSize;
            final stoneSize = cellSize * 0.9;
            final padding = cellSize / 2;

            return Stack(
              children: [
                // Grid lines
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _BoardPainter(cellSize, padding),
                ),

                // Star points
                ...starPoints.map((point) {
                  return Positioned(
                    left: padding + point[1] * cellSize - 4,
                    top: padding + point[0] * cellSize - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.boardLineColor,
                      ),
                    ),
                  );
                }),

                // Stones and touch areas
                ...List.generate(boardSize, (y) {
                  return List.generate(boardSize, (x) {
                    final stone = board[y][x];
                    return Positioned(
                      left: padding + x * cellSize - stoneSize / 2,
                      top: padding + y * cellSize - stoneSize / 2,
                      child: GestureDetector(
                        onTap: stone == 0 && isMyTurn
                            ? () => onCellTap(x, y)
                            : null,
                        child: Container(
                          width: stoneSize,
                          height: stoneSize,
                          color: Colors.transparent,
                          child: stone != 0
                              ? StoneWidget(
                                  isBlack: stone == 1,
                                  isLastMove: x == lastMoveX && y == lastMoveY,
                                  size: stoneSize,
                                )
                              : null,
                        ),
                      ),
                    );
                  });
                }).expand((e) => e),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double cellSize;
  final double padding;

  _BoardPainter(this.cellSize, this.padding);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.boardLineColor
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i < GameBoardWidget.boardSize; i++) {
      final y = padding + i * cellSize;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        paint,
      );
    }

    // Draw vertical lines
    for (int i = 0; i < GameBoardWidget.boardSize; i++) {
      final x = padding + i * cellSize;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
