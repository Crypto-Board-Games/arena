import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/lobby');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
              const Color(0xFF1A1F2E),
              AppTheme.bgBasicDark.withOpacity(0.9),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
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
                            child: Transform.translate(
                              offset: Offset(0, offset),
                              child: Container(
                                width: 80.w,
                                height: 1,
                                color: AppTheme.boardLineColor.withOpacity(0.5),
                              ),
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
                        Positioned(child: _buildStone(true)),
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
                        : () => ref
                              .read(authProvider.notifier)
                              .signInWithGoogle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    );
                  },
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLogo(BuildContext context, bool isSmallScreen) {
    final logoSize = responsive<double>(
      context,
      mobile: isSmallScreen ? 100 : 120,
      desktop: 140,
    );

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.main.withOpacity(0.9),
                AppTheme.sub.withOpacity(0.7),
                AppTheme.main.withOpacity(0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.main.withOpacity(_pulseAnimation.value),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppTheme.main.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.boardColor,
                border: Border.all(
                  color: AppTheme.main.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(5, (i) {
                    final offset = (i - 2) * (logoSize * 0.12);
                    return Positioned(
                      child: Container(
                        width: logoSize * 0.65,
                        height: 1.5,
                        color: AppTheme.boardLineColor.withOpacity(0.45),
                        margin: EdgeInsets.only(top: offset < 0 ? 0 : offset),
                      ),
                    );
                  }),
                  ...List.generate(5, (i) {
                    final offset = (i - 2) * (logoSize * 0.12);
                    return Positioned(
                      child: Container(
                        width: 1.5,
                        height: logoSize * 0.65,
                        color: AppTheme.boardLineColor.withOpacity(0.45),
                        margin: EdgeInsets.only(left: offset < 0 ? 0 : offset),
                      ),
                    );
                  }),
                  Positioned(
                    left: logoSize * 0.22,
                    top: logoSize * 0.22,
                    child: _buildEnhancedStone(true, logoSize * 0.18),
                  ),
                  Positioned(
                    right: logoSize * 0.22,
                    bottom: logoSize * 0.22,
                    child: _buildEnhancedStone(false, logoSize * 0.18),
                  ),
                  Positioned(child: _buildEnhancedStone(true, logoSize * 0.15)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStone(bool isBlack, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBlack ? AppTheme.blackStone : AppTheme.whiteStone,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
          BoxShadow(
            color: isBlack
                ? Colors.black.withOpacity(0.25)
                : Colors.white.withOpacity(0.45),
            blurRadius: 3,
            offset: const Offset(-1, -1),
          ),
        ],
        gradient: isBlack
            ? const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Color(0xFF2A2A2A), AppTheme.blackStone],
              )
            : const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Colors.white, Color(0xFFE8E8E8)],
              ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Text(
          'Arena',
          style: TextStyle(
            fontSize: responsive(context, mobile: 44, desktop: 56),
            fontWeight: FontWeight.bold,
            color: AppTheme.fontPrimaryDark,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: AppTheme.main.withOpacity(_pulseAnimation.value),
                blurRadius: 25,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: AppTheme.sub.withOpacity(_pulseAnimation.value * 0.5),
                blurRadius: 40,
                offset: const Offset(0, 3),
              ),
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.main.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.main.withOpacity(0.2), width: 1),
      ),
      child: Text(
        '온라인 오목 대전',
        style: TextStyle(
          fontSize: responsive(context, mobile: 14, desktop: 17),
          color: AppTheme.fontSecondaryDark,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.bgContentsDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.main.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnhancedFeatureRow(
            icon: Icons.people_outline,
            text: '실시간 매칭',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildEnhancedFeatureRow(
            icon: Icons.emoji_events_outlined,
            text: 'Elo 랭킹 시스템',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildEnhancedFeatureRow(
            icon: Icons.timer_outlined,
            text: '제한시간 대전',
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeatureRow({
    required IconData icon,
    required String text,
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.main.withOpacity(0.18),
                AppTheme.sub.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.main.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.main,
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 14),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: AppTheme.fontSecondaryDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Google Sign-In Button - Following Official Brand Guidelines
  /// https://developers.google.com/identity/branding-guidelines
  Widget _buildGoogleSignInButton(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    // Google Brand Guidelines:
    // - Light theme: Fill #FFFFFF, Stroke #747775 1px, Font #1F1F1F
    // - Font: Roboto Medium, 14px
    // - iOS Padding: 16px left, 12px between logo and text, 16px right
    // - Minimum height: 40px (using 48px for better touch target)
    // - Logo: Standard Google G on white background

    return Container(
      width: double.infinity,
      height: 48, // Standard height following Google guidelines
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white, // Google Light theme: #FFFFFF
        borderRadius: BorderRadius.circular(
          24,
        ), // Pill shape (Google preferred)
        border: Border.all(
          color: const Color(0xFF747775), // Google Light theme stroke
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: authState.isLoading
              ? null
              : () => ref.read(authProvider.notifier).signInWithGoogle(),
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.black.withOpacity(0.05),
          highlightColor: Colors.black.withOpacity(0.03),
          child: authState.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1F1F1F), // Google text color
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left padding: 16px (iOS standard)
                    const SizedBox(width: 16),

                    // Google G Logo - Standard colors on white background
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to text if image fails
                            return const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Space between logo and text: 12px (iOS standard)
                    const SizedBox(width: 12),

                    // Button text - Following Google guidelines
                    const Text(
                      'Sign in with Google', // English as per Google guidelines
                      style: TextStyle(
                        color: Color(
                          0xFF1F1F1F,
                        ), // Google Light theme font color
                        fontSize: 14, // Google recommended font size
                        fontWeight: FontWeight.w500, // Roboto Medium equivalent
                        letterSpacing: 0.25,
                        fontFamily:
                            'Roboto', // Will fallback to system if not available
                      ),
                    ),

                    // Right padding: 16px (iOS standard)
                    const SizedBox(width: 16),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgContentsDark.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '로그인하면 서비스 이용약관에 동의하게 됩니다',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.fontHideDark,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
