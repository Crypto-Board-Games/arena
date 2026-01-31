import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_layout.dart';
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
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgBasicDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgBasicDark,
              AppTheme.bgContentsDark,
              const Color(0xFF1A1F2E), // Subtle blue tint
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 420,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo with glassmorphism effect
                _buildLogo(context),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Arena',
                  style: TextStyle(
                    fontSize: responsive(context, mobile: 42, desktop: 52),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.fontPrimaryDark,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(
                        color: AppTheme.main.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  '온라인 오목 대전',
                  style: TextStyle(
                    fontSize: responsive(context, mobile: 15, desktop: 17),
                    color: AppTheme.fontSecondaryDark,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 60),

                // Feature highlights
                _buildFeatureRow(
                  icon: Icons.people_outline,
                  text: '실시간 매칭',
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: Icons.emoji_events_outlined,
                  text: 'Elo 랭킹 시스템',
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: Icons.timer_outlined,
                  text: '제한시간 대전',
                ),

                const Spacer(flex: 2),

                // Google Sign In Button with modern design
                _buildGoogleSignInButton(context, ref, authState),

                const SizedBox(height: 24),

                // Terms text
                Text(
                  '로그인하면 서비스 이용약관에 동의하게 됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.fontHideDark,
                  ),
                  textAlign: TextAlign.center,
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
    final logoSize = responsive<double>(context, mobile: 110, desktop: 130);
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.boardColor,
            border: Border.all(
              color: AppTheme.main.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid lines
              ...List.generate(5, (i) {
                final offset = (i - 2) * (logoSize * 0.12);
                return Positioned(
                  child: Container(
                    width: logoSize * 0.65,
                    height: 1.5,
                    color: AppTheme.boardLineColor.withOpacity(0.4),
                    margin: EdgeInsets.only(top: offset),
                  ),
                );
              }),
              ...List.generate(5, (i) {
                final offset = (i - 2) * (logoSize * 0.12);
                return Positioned(
                  child: Container(
                    width: 1.5,
                    height: logoSize * 0.65,
                    color: AppTheme.boardLineColor.withOpacity(0.4),
                    margin: EdgeInsets.only(left: offset),
                  ),
                );
              }),
              // Stones with modern styling
              Positioned(
                left: logoSize * 0.22,
                top: logoSize * 0.22,
                child: _buildStone(true, logoSize * 0.18),
              ),
              Positioned(
                right: logoSize * 0.22,
                bottom: logoSize * 0.22,
                child: _buildStone(false, logoSize * 0.18),
              ),
              Positioned(
                child: _buildStone(true, logoSize * 0.15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStone(bool isBlack, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBlack ? AppTheme.blackStone : AppTheme.whiteStone,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
        gradient: isBlack
            ? null
            : const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Colors.white, Color(0xFFE8E8E8)],
              ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.main.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.main,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.fontSecondaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.white,
            const Color(0xFFF8F9FA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.main.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authState.isLoading
              ? null
              : () => ref.read(authProvider.notifier).signInWithGoogle(),
          borderRadius: BorderRadius.circular(16),
          child: authState.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.main,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Google로 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.fontPrimaryLight,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
