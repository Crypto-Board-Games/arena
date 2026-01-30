import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/matchmaking_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final matchmakingState = ref.watch(matchmakingProvider);
    final user = authState.user;

    ref.listen<MatchmakingState>(matchmakingProvider, (previous, next) {
      if (next.isMatchFound && next.gameId != null) {
        ref.read(matchmakingProvider.notifier).reset();
        context.go('/game/${next.gameId}');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // User Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                        border: Border.all(
                          color: AppTheme.accent,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      user?.displayName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Elo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Elo ${user?.elo ?? 1200}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('승', user?.wins ?? 0, AppTheme.success),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.surfaceLight,
                        ),
                        _buildStat('패', user?.losses ?? 0, AppTheme.error),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.surfaceLight,
                        ),
                        _buildStat(
                          '승률',
                          user != null && user.totalGames > 0
                              ? '${user.winRate.toStringAsFixed(1)}%'
                              : '-',
                          AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Matchmaking Button
              if (matchmakingState.isSearching)
                Column(
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '상대를 찾는 중...',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        ref.read(matchmakingProvider.notifier).cancelSearch();
                      },
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(matchmakingProvider.notifier).startSearching();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports, size: 28),
                        SizedBox(width: 12),
                        Text(
                          '대전 찾기',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
