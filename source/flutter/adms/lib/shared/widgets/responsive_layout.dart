import 'package:flutter/material.dart';

// =============================================================================
// BREAKPOINTS
// =============================================================================

/// Responsive breakpoints matching DESIGN_GUIDELINES.md specification.
///
/// - Mobile:  ≤ 767px
/// - Tablet:  768px – 1199px
/// - Desktop: ≥ 1200px
class Breakpoints {
  static const double mobile = 767;
  static const double tablet = 1199;

  /// Returns true if the screen width is in the mobile range.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobile;

  /// Returns true if the screen width is in the tablet range.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobile && width <= tablet;
  }

  /// Returns true if the screen width is in the desktop range.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tablet;
}

// =============================================================================
// RESPONSIVE BUILDER
// =============================================================================

/// Builds different layouts based on screen width breakpoints.
///
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Layout for screens ≤ 767px (required).
  final Widget Function(BuildContext context) mobile;

  /// Layout for screens 768px – 1199px. Falls back to [mobile] if null.
  final Widget Function(BuildContext context)? tablet;

  /// Layout for screens ≥ 1200px. Falls back to [tablet] then [mobile] if null.
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > Breakpoints.tablet) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (constraints.maxWidth > Breakpoints.mobile) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}

// =============================================================================
// RESPONSIVE VALUE
// =============================================================================

/// Returns a value based on the current screen size breakpoint.
///
/// ```dart
/// final padding = ResponsiveValue.of(
///   context,
///   mobile: 16.0,
///   tablet: 24.0,
///   desktop: 32.0,
/// );
/// ```
class ResponsiveValue {
  /// Pick a value based on the current breakpoint.
  static T of<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (Breakpoints.isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (Breakpoints.isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

// =============================================================================
// RESPONSIVE PADDING
// =============================================================================

/// Applies responsive padding based on screen size.
///
/// Automatically adjusts from 16px (mobile) → 24px (tablet) → 32px (desktop).
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveValue.of<double>(
      context,
      mobile: mobilePadding ?? 16,
      tablet: tabletPadding ?? 24,
      desktop: desktopPadding ?? 32,
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

// =============================================================================
// RESPONSIVE GRID
// =============================================================================

/// A grid that adapts its column count to the screen size.
///
/// ```dart
/// ResponsiveGrid(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 4,
///   children: [...],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveValue.of<int>(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// =============================================================================
// RESPONSIVE SIDEBAR LAYOUT
// =============================================================================

/// A layout with a sidebar on desktop/tablet and bottom navigation on mobile.
///
/// Used by admin dashboards to provide collapsible navigation.
class ResponsiveSidebarLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget body;
  final Widget? bottomNav;
  final double sidebarWidth;

  const ResponsiveSidebarLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.bottomNav,
    this.sidebarWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => Scaffold(
        body: body,
        bottomNavigationBar: bottomNav,
      ),
      tablet: (_) => Scaffold(
        body: Row(
          children: [
            SizedBox(width: sidebarWidth * 0.75, child: sidebar),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
      desktop: (_) => Scaffold(
        body: Row(
          children: [
            SizedBox(width: sidebarWidth, child: sidebar),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CONNECTIVITY BANNER
// =============================================================================

/// Shows an offline banner at the top of the screen when network is unavailable.
class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isOnline)
          MaterialBanner(
            content: const Text(
              'You are currently offline. Changes will sync when reconnected.',
            ),
            leading: const Icon(Icons.wifi_off, color: Colors.white),
            backgroundColor: Colors.orange.shade800,
            contentTextStyle: const TextStyle(color: Colors.white),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: child),
      ],
    );
  }
}
