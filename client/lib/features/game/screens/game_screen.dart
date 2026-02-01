import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
            backgroundColor: AppTheme.error,
          ),
        );
        ref.read(gameProvider.notifier).clearError();
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (gameState.status == GameStatus.inProgress) {
          final shouldLeave = await _showLeaveConfirmDialog(context);
          if (shouldLeave == true) {
            await ref.read(gameProvider.notifier).resign();
          }
          return false;
        }
        await ref.read(gameProvider.notifier).leaveGame();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
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
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                // Opponent info
                _buildPlayerInfo(
                  name: gameState.opponentName ?? '상대방',
                  elo: gameState.opponentElo,
                  isCurrentTurn: !gameState.isMyTurn,
                  remainingSeconds: !gameState.isMyTurn
                      ? gameState.remainingSeconds
                      : null,
                  color: gameState.myColor == 'black' ? 'white' : 'black',
                  isConnected: gameState.opponentConnected,
                ),

                SizedBox(height: 16.h),

                // Game Board
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

                SizedBox(height: 16.h),

                // My info
                _buildPlayerInfo(
                  name: '나',
                  isCurrentTurn: gameState.isMyTurn,
                  remainingSeconds: gameState.isMyTurn
                      ? gameState.remainingSeconds
                      : null,
                  color: gameState.myColor ?? 'black',
                  showResign: gameState.status == GameStatus.inProgress,
                  onResign: () => _showResignConfirmDialog(context),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    int? elo,
    required bool isCurrentTurn,
    int? remainingSeconds,
    required String color,
    bool isConnected = true,
    bool showResign = false,
    VoidCallback? onResign,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCurrentTurn ? AppTheme.surfaceLight : AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: isCurrentTurn
            ? Border.all(color: AppTheme.accent, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Stone indicator
          Container(
            width: 32.w,
            height: 32.w,
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (!isConnected) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '연결 끊김',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (elo != null)
                  Text(
                    'Elo $elo',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Timer or Resign button
          if (remainingSeconds != null && isCurrentTurn)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: remainingSeconds <= 10
                    ? AppTheme.error.withOpacity(0.2)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${remainingSeconds}s',
                style: TextStyle(
                  fontSize: 20.sp,
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
        backgroundColor: AppTheme.surface,
        title: const Text('게임 나가기'),
        content: const Text('게임 중에 나가면 기권 처리됩니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResignConfirmDialog(BuildContext context) async {
    final shouldResign = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('기권'),
        content: const Text('정말 기권하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('기권', style: TextStyle(color: AppTheme.error)),
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
        backgroundColor: AppTheme.surface,
        title: Text(
          isWinner ? '승리!' : '패배',
          style: TextStyle(
            color: isWinner ? AppTheme.success : AppTheme.error,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getEndReasonText(state.endReason),
              style: TextStyle(fontSize: 16.sp, color: AppTheme.textSecondary),
            ),
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
              child: const Text('홈으로'),
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
