import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive container that centers content with max width on larger screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerVertically;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding,
    this.centerVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > Breakpoints.mobile;
        
        Widget content = Container(
          width: isWideScreen ? maxWidth : double.infinity,
          padding: padding,
          child: child,
        );

        if (isWideScreen) {
          content = Center(child: content);
        }

        return content;
      },
    );
  }
}

/// Responsive scaffold that adapts to screen size
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final double maxContentWidth;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.maxContentWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: ResponsiveContainer(
        maxWidth: maxContentWidth,
        child: body,
      ),
    );
  }
}

/// Helper extension to check screen size
extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < Breakpoints.mobile;
  bool get isTablet => 
      MediaQuery.of(this).size.width >= Breakpoints.mobile &&
      MediaQuery.of(this).size.width < Breakpoints.desktop;
  bool get isDesktop => MediaQuery.of(this).size.width >= Breakpoints.desktop;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Responsive value selector
T responsive<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  if (context.isDesktop && desktop != null) return desktop;
  if (context.isTablet && tablet != null) return tablet;
  return mobile;
}
