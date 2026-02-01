import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // User Profile Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
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
                  ],
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
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
