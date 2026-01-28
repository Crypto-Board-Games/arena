import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppTheme.boardColor,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Grid lines
                        ...List.generate(5, (i) {
                          final offset = (i - 2) * 20.0;
                          return Positioned(
                            child: Container(
                              width: 80.w,
                              height: 1,
                              color: AppTheme.boardLineColor.withOpacity(0.5),
                              margin: EdgeInsets.only(top: offset),
                            ),
                          );
                        }),
                        // Stones
                        Positioned(
                          left: 25.w,
                          top: 25.w,
                          child: _buildStone(true),
                        ),
                        Positioned(
                          right: 25.w,
                          bottom: 25.w,
                          child: _buildStone(false),
                        ),
                        Positioned(
                          child: _buildStone(true),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Title
                Text(
                  'Arena',
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                Text(
                  '온라인 오목 대전',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).signInWithGoogle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    child: authState.isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                width: 24.w,
                                height: 24.w,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.g_mobiledata,
                                  size: 28.sp,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Google로 로그인',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildStone(bool isBlack) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBlack ? AppTheme.blackStone : AppTheme.whiteStone,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        gradient: isBlack
            ? null
            : const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Colors.white, Color(0xFFE0E0E0)],
              ),
      ),
    );
  }
}
