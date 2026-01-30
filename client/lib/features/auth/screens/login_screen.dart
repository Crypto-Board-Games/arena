import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

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
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 400,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                _buildLogo(context),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Arena',
                  style: TextStyle(
                    fontSize: responsive(context, mobile: 40, desktop: 48),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '온라인 오목 대전',
                  style: TextStyle(
                    fontSize: responsive(context, mobile: 14, desktop: 16),
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(flex: 2),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => ref
                              .read(authProvider.notifier)
                              .signInWithGoogle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                width: 24,
                                height: 24,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google로 로그인',
                                style: TextStyle(
                                  fontSize: 16,
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

  Widget _buildLogo(BuildContext context) {
    final logoSize = responsive<double>(context, mobile: 100, desktop: 120);
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppTheme.boardColor,
        borderRadius: BorderRadius.circular(24),
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
              final offset = (i - 2) * 16.0;
              return Positioned(
                child: Container(
                  width: logoSize * 0.7,
                  height: 1,
                  color: AppTheme.boardLineColor.withOpacity(0.5),
                  margin: EdgeInsets.only(top: offset),
                ),
              );
            }),
            // Stones
            Positioned(
              left: logoSize * 0.2,
              top: logoSize * 0.2,
              child: _buildStone(true),
            ),
            Positioned(
              right: logoSize * 0.2,
              bottom: logoSize * 0.2,
              child: _buildStone(false),
            ),
            Positioned(
              child: _buildStone(true),
            ),
          ],
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
