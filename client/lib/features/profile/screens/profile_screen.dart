import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                _row('ELO', '${user?.elo ?? 1200}'),
                _row('승', '${user?.wins ?? 0}'),
                _row('패', '${user?.losses ?? 0}'),
                _row(
                  '승률',
                  user != null && user.totalGames > 0
                      ? '${user.winRate.toStringAsFixed(1)}%'
                      : '0%',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
