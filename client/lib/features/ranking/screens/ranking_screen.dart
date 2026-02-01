import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../services/ranking_service.dart';
import '../../auth/providers/auth_provider.dart';

final rankingServiceProvider = Provider<RankingService>(
  (ref) => RankingService(),
);

final rankingsProvider = FutureProvider<RankingResponse>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) {
    throw Exception('Not authenticated');
  }

  return ref.watch(rankingServiceProvider).fetchRankings(token);
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRankings = ref.watch(rankingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('랭킹'), centerTitle: true),
      body: SafeArea(
        child: asyncRankings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Failed to load rankings: $err')),
          data: (data) {
            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: data.rankings.length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppTheme.surfaceLight),
              itemBuilder: (context, index) {
                final entry = data.rankings[index];
                final isMe = entry.rank == data.myRank;

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.surfaceLight : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36.w,
                        child: Text(
                          '${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.displayName,
                          style: TextStyle(color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.elo}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
