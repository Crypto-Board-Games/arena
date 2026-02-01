import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../providers/game_provider.dart';
import '../providers/game_state.dart';
import '../widgets/game_board_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int? lastMoveX;
  int? lastMoveY;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).joinGame(widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.status == GameStatus.ended) {
        _showGameEndDialog(context, next);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(gameProvider.notifier).clearError();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (gameState.status == GameStatus.inProgress) {
          final shouldLeave = await _showLeaveConfirmDialog(context);
          if (shouldLeave == true) {
            await ref.read(gameProvider.notifier).resign();
            if (mounted) context.go('/home');
          }
        } else {
          await ref.read(gameProvider.notifier).leaveGame();
          if (mounted) context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgBasicDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (gameState.status == GameStatus.inProgress) {
                final shouldLeave = await _showLeaveConfirmDialog(context);
                if (shouldLeave == true) {
                  await ref.read(gameProvider.notifier).resign();
                  if (mounted) context.go('/lobby');
                }
              } else {
                await ref.read(gameProvider.notifier).leaveGame();
                if (mounted) context.go('/lobby');
              }
            },
          ),
          actions: [
            if (gameState.status == GameStatus.inProgress)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.flag_rounded,
                    color: AppTheme.red,
                  ),
                  onPressed: () => _showResignConfirmDialog(context),
                  tooltip: '기권',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Opponent info card
                _buildPlayerCard(
                  name: gameState.opponentName ?? '상대방',
                  elo: gameState.opponentElo,
                  isCurrentTurn: !gameState.isMyTurn,
                  remainingSeconds: !gameState.isMyTurn
                      ? gameState.remainingSeconds
                      : null,
                  color: gameState.myColor == 'black' ? 'white' : 'black',
                  isConnected: gameState.opponentConnected,
                  isOpponent: true,
                ),

                const SizedBox(height: 20),

                // Game Board with modern container
                Expanded(
                  child: Center(
                    child: gameState.status == GameStatus.connecting
                        ? const CircularProgressIndicator(
                            color: AppTheme.accent,
                          )
                        : GameBoardWidget(
                            board: gameState.board,
                            isMyTurn:
                                gameState.isMyTurn && !gameState.isGameOver,
                            onCellTap: (x, y) {
                              setState(() {
                                lastMoveX = x;
                                lastMoveY = y;
                              });
                              ref.read(gameProvider.notifier).placeStone(x, y);
                            },
                            lastMoveX: lastMoveX,
                            lastMoveY: lastMoveY,
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // My info card
                _buildPlayerCard(
                  name: '나',
                  isCurrentTurn: gameState.isMyTurn,
                  remainingSeconds: gameState.isMyTurn
                      ? gameState.remainingSeconds
                      : null,
                  color: gameState.myColor ?? 'black',
                  isConnected: true,
                  isOpponent: false,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    int? elo,
    required bool isCurrentTurn,
    int? remainingSeconds,
    required String color,
    required bool isConnected,
    required bool isOpponent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTurn 
            ? AppTheme.bgContentsDark 
            : AppTheme.bgContentsDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentTurn
            ? Border.all(color: AppTheme.main.withOpacity(0.5), width: 2)
            : null,
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: AppTheme.main.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Stone indicator with glow effect
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color == 'black'
                  ? AppTheme.blackStone
                  : AppTheme.whiteStone,
              border: Border.all(color: Colors.grey, width: 1),
            ),
          ),
          SizedBox(width: 12.w),

          // Name and Elo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentTurn 
                            ? AppTheme.fontPrimaryDark 
                            : AppTheme.fontSecondaryDark,
                      ),
                    ),
                    if (!isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '연결 끊김',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (isCurrentTurn) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.main,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.main.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (elo != null)
                  Text(
                    'Elo $elo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.fontTertiaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Timer or Resign button
          if (remainingSeconds != null && isCurrentTurn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: remainingSeconds <= 10
                    ? AppTheme.red.withOpacity(0.15)
                    : AppTheme.main.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: remainingSeconds <= 10
                    ? Border.all(color: AppTheme.red.withOpacity(0.3))
                    : null,
              ),
              child: Text(
                '${remainingSeconds}s',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: remainingSeconds <= 10
                      ? AppTheme.error
                      : AppTheme.textPrimary,
                ),
              ),
            )
          else if (showResign)
            TextButton(
              onPressed: onResign,
              child: Text(
                '기권',
                style: TextStyle(fontSize: 14.sp, color: AppTheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showLeaveConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgContentsDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '게임 나가기',
          style: TextStyle(
            color: AppTheme.fontPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '게임 중에 나가면 기권 처리됩니다.\n정말 나가시겠습니까?',
          style: TextStyle(color: AppTheme.fontSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppTheme.fontTertiaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResignConfirmDialog(BuildContext context) async {
    final shouldResign = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgContentsDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '기권',
          style: TextStyle(
            color: AppTheme.fontPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 기권하시겠습니까?',
          style: TextStyle(color: AppTheme.fontSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppTheme.fontTertiaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('기권'),
          ),
        ],
      ),
    );

    if (shouldResign == true) {
      await ref.read(gameProvider.notifier).resign();
    }
  }

  void _showGameEndDialog(BuildContext context, GameState state) {
    final isWinner = state.myColor == 'black'
        ? state.winnerId == state.gameId
        : state.winnerId != state.gameId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgContentsDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // Result icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWinner 
                    ? AppTheme.green.withOpacity(0.15)
                    : AppTheme.red.withOpacity(0.15),
              ),
              child: Icon(
                isWinner ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 40,
                color: isWinner ? AppTheme.green : AppTheme.red,
              ),
            ),
            const SizedBox(height: 24),
            // Result text
            Text(
              _getEndReasonText(state.endReason),
              style: TextStyle(fontSize: 16.sp, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            // End reason
            Text(
              _getEndReasonText(state.endReason),
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.fontSecondaryDark,
              ),
            ),
            // Elo change
            if (state.eloChange != null) ...[
              SizedBox(height: 16.h),
              Text(
                'Elo ${state.eloChange! >= 0 ? '+' : ''}${state.eloChange}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: state.eloChange! >= 0
                      ? AppTheme.success
                      : AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(gameProvider.notifier).leaveGame();
                context.go('/lobby');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.main,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '홈으로',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEndReasonText(String? reason) {
    switch (reason) {
      case 'five_in_row':
        return '5목 완성!';
      case 'resign':
        return '기권';
      case 'timeout':
        return '시간 초과';
      case 'disconnect':
        return '연결 끊김';
      default:
        return '게임 종료';
    }
  }
}
