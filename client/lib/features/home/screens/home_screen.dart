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
        border: Border.all(color: AppTheme.main.withOpacity(0.2), width: 1),
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
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                        border: Border.all(color: AppTheme.accent, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Name
                    Text(
                      user?.displayName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Elo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: AppTheme.accent, size: 20.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'Elo ${user?.elo ?? 1200}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('승', user?.wins ?? 0, AppTheme.success),
                        Container(
                          width: 1,
                          height: 40.h,
                          color: AppTheme.surfaceLight,
                        ),
                        _buildStat('패', user?.losses ?? 0, AppTheme.error),
                        Container(
                          width: 1,
                          height: 40.h,
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
                  ),
                ),
              ),

              const Spacer(),

              // Matchmaking Button
              if (matchmakingState.isSearching)
                Column(
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.accent,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      '상대를 찾는 중...',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '대기 ${matchmakingState.waitingSeconds}s · 범위 ±${matchmakingState.currentRange}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    TextButton(
                      onPressed: () {
                        ref.read(matchmakingProvider.notifier).cancelSearch();
                      },
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 64.h,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(matchmakingProvider.notifier).startSearching();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports, size: 28.sp),
                        SizedBox(width: 12.w),
                        Text(
                          '대전 찾기',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/ranking'),
                      child: const Text('랭킹'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/profile'),
                      child: const Text('프로필'),
                    ),
                  ),
                ],
              ),
            ],
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
          Container(width: 1, height: 50, color: AppTheme.bgBorderDark),
          _buildStat(
            label: '패배',
            value: user?.losses ?? 0,
            color: AppTheme.red,
            icon: Icons.trending_down_rounded,
          ),
          Container(width: 1, height: 50, color: AppTheme.bgBorderDark),
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
            Icon(icon, color: color, size: 16),
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
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
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
          colors: [AppTheme.main, AppTheme.sub],
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
          onTap: () {
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
        border: Border.all(color: AppTheme.main.withOpacity(0.3), width: 2),
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
            style: TextStyle(fontSize: 14, color: AppTheme.fontTertiaryDark),
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
