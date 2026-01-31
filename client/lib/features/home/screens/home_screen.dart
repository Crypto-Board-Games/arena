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
      backgroundColor: AppTheme.bgBasicDark,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header with logout
              _buildHeader(context, ref),
              
              const SizedBox(height: 24),

              // User Profile Card with modern design
              _buildProfileCard(context, user),
              
              const SizedBox(height: 24),

              // Stats Section
              _buildStatsSection(user),
              
              const Spacer(),

              // Matchmaking Button with modern design
              matchmakingState.isSearching
                  ? _buildSearchingState(context, ref)
                  : _buildMatchmakingButton(context, ref),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.main.withOpacity(0.8),
                    AppTheme.sub.withOpacity(0.6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.grid_on_rounded,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Arena',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.fontPrimaryDark,
              ),
            ),
          ],
        ),
        
        // Logout button
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgContentsDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.fontSecondaryDark,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bgContentsDark,
            AppTheme.bgContentsDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.main.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.main.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with glow effect
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.main.withOpacity(0.8),
                  AppTheme.sub.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.main.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgContentsDark,
                ),
                child: Center(
                  child: Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.fontPrimaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            user?.displayName ?? 'Unknown',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.fontPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          
          // Elo with badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.main.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.main,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Elo ${user?.elo ?? 1200}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.main,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgContentsDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(
            label: '승리',
            value: user?.wins ?? 0,
            color: AppTheme.green,
            icon: Icons.trending_up_rounded,
          ),
          Container(
            width: 1,
            height: 50,
            color: AppTheme.bgBorderDark,
          ),
          _buildStat(
            label: '패배',
            value: user?.losses ?? 0,
            color: AppTheme.red,
            icon: Icons.trending_down_rounded,
          ),
          Container(
            width: 1,
            height: 50,
            color: AppTheme.bgBorderDark,
          ),
          _buildStat(
            label: '승률',
            value: user != null && user.totalGames > 0
                ? '${user.winRate.toStringAsFixed(1)}%'
                : '-',
            color: AppTheme.fontSecondaryDark,
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required dynamic value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.fontTertiaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchmakingButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.main,
            AppTheme.sub,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.main.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onPressed: () {
            ref.read(matchmakingProvider.notifier).startSearching();
          },
          borderRadius: BorderRadius.circular(20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports_rounded,
                size: 32,
                color: AppTheme.white,
              ),
              SizedBox(width: 14),
              Text(
                '대전 찾기',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgContentsDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.main.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Animated progress indicator
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.main.withOpacity(0.1),
                  ),
                ),
                const SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppTheme.main,
                  ),
                ),
                const Icon(
                  Icons.search_rounded,
                  color: AppTheme.main,
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '상대를 찾는 중...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.fontPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '실력이 비슷한 상대와 매칭됩니다',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.fontTertiaryDark,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              ref.read(matchmakingProvider.notifier).cancelSearch();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.red,
              size: 20,
            ),
            label: const Text(
              '취소',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppTheme.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
