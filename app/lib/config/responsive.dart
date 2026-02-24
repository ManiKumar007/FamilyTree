import 'package:flutter/material.dart';
import 'theme.dart';

/// Device type enum for responsive layouts
enum DeviceType { mobile, tablet, desktop }

/// Responsive utility class that provides screen-aware sizing, breakpoints,
/// and layout helpers. Use this across all screens for consistent responsiveness.
class Responsive {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final DeviceType deviceType;
  late final double scaleFactor;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    deviceType = _getDeviceType();
    scaleFactor = _getScaleFactor();
  }

  DeviceType _getDeviceType() {
    if (screenWidth < AppSizing.breakpointTablet) return DeviceType.mobile;
    if (screenWidth < AppSizing.breakpointDesktop) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  double _getScaleFactor() {
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth / 375.0; // Base: iPhone SE width
      case DeviceType.tablet:
        return screenWidth / 768.0; // Base: iPad width
      case DeviceType.desktop:
        return 1.0; // No scaling for desktop
    }
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Returns value based on device type
  T value<T>({required T mobile, T? tablet, required T desktop}) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? desktop;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Responsive font size — scales based on screen width
  double fontSize(double baseSize) {
    final scale = (screenWidth / 375.0).clamp(0.8, 1.4);
    return baseSize * scale;
  }

  /// Responsive spacing — scales based on device type
  double spacing(double baseSpacing) {
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing * 0.8;
      case DeviceType.tablet:
        return baseSpacing;
      case DeviceType.desktop:
        return baseSpacing * 1.2;
    }
  }

  /// Responsive icon size
  double iconSize(double baseSize) {
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize * 0.9;
      case DeviceType.tablet:
        return baseSize;
      case DeviceType.desktop:
        return baseSize * 1.1;
    }
  }

  /// Content max width with proper centering
  double get contentMaxWidth {
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth;
      case DeviceType.tablet:
        return 720;
      case DeviceType.desktop:
        return AppSizing.maxContentWidth;
    }
  }

  /// Form max width
  double get formMaxWidth {
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth;
      case DeviceType.tablet:
        return AppSizing.maxFormWidth;
      case DeviceType.desktop:
        return AppSizing.maxFormWidth;
    }
  }

  /// Grid cross-axis count for card grids
  int get gridColumns {
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= AppSizing.breakpointDesktop) return 3;
    if (screenWidth >= AppSizing.breakpointTablet) return 2;
    return 1;
  }

  /// Grid cross-axis count for stat cards
  int get statCardColumns {
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= AppSizing.breakpointDesktop) return 3;
    if (screenWidth >= AppSizing.breakpointTablet) return 2;
    return 2;
  }

  /// Horizontal padding for page content
  double get horizontalPadding {
    switch (deviceType) {
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.tablet:
        return 24.0;
      case DeviceType.desktop:
        return 32.0;
    }
  }

  /// Responsive SliverAppBar expandedHeight
  double get appBarExpandedHeight {
    switch (deviceType) {
      case DeviceType.mobile:
        return 220;
      case DeviceType.tablet:
        return 260;
      case DeviceType.desktop:
        return 300;
    }
  }

  /// Chart height responsive
  double get chartHeight {
    switch (deviceType) {
      case DeviceType.mobile:
        return 220;
      case DeviceType.tablet:
        return 280;
      case DeviceType.desktop:
        return 350;
    }
  }

  /// Tree view card dimensions
  double get treeCardWidth {
    switch (deviceType) {
      case DeviceType.mobile:
        return 120;
      case DeviceType.tablet:
        return 140;
      case DeviceType.desktop:
        return 160;
    }
  }

  double get treeCardHeight {
    switch (deviceType) {
      case DeviceType.mobile:
        return 135;
      case DeviceType.tablet:
        return 145;
      case DeviceType.desktop:
        return 160;
    }
  }

  double get treeHGap {
    switch (deviceType) {
      case DeviceType.mobile:
        return 30;
      case DeviceType.tablet:
        return 50;
      case DeviceType.desktop:
        return 60;
    }
  }

  double get treeVGap {
    switch (deviceType) {
      case DeviceType.mobile:
        return 60;
      case DeviceType.tablet:
        return 80;
      case DeviceType.desktop:
        return 100;
    }
  }

  double get treeSpouseGap {
    switch (deviceType) {
      case DeviceType.mobile:
        return 15;
      case DeviceType.tablet:
        return 25;
      case DeviceType.desktop:
        return 30;
    }
  }

  double get treeAddBtnWidth {
    switch (deviceType) {
      case DeviceType.mobile:
        return 90;
      case DeviceType.tablet:
        return 110;
      case DeviceType.desktop:
        return 120;
    }
  }

  double get treePadding {
    switch (deviceType) {
      case DeviceType.mobile:
        return 100;
      case DeviceType.tablet:
        return 150;
      case DeviceType.desktop:
        return 200;
    }
  }
}

/// A responsive layout builder widget that provides the Responsive context
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = Responsive(context);
        return builder(context, responsive);
      },
    );
  }
}

/// Wraps content in a centered constrained box for consistent max-width
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? responsive.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Responsive grid that auto-adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minChildWidth;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minChildWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / minChildWidth).floor().clamp(1, 4);
        final childWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: childWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
