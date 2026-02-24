import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Wrapper for AnimationLimiter to manage list animations
class AnimatedListWrapper extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final Duration duration;
  final double horizontalOffset;
  final double verticalOffset;

  const AnimatedListWrapper({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.duration = const Duration(milliseconds: 375),
    this.horizontalOffset = 50.0,
    this.verticalOffset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        scrollDirection: scrollDirection,
        itemCount: children.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: duration,
            child: SlideAnimation(
              horizontalOffset: scrollDirection == Axis.horizontal ? horizontalOffset : 0,
              verticalOffset: scrollDirection == Axis.vertical ? verticalOffset : 0,
              child: FadeInAnimation(
                child: children[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated grid wrapper
class AnimatedGridWrapper extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Duration duration;

  const AnimatedGridWrapper({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: duration,
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: children[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated column with staggered children
class AnimatedStaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedStaggeredColumn({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 375),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

/// Animated row with staggered children
class AnimatedStaggeredRow extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedStaggeredRow({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 375),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

/// Animated wrap with staggered children
class AnimatedStaggeredWrap extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final Axis direction;
  final WrapAlignment alignment;
  final double spacing;
  final WrapAlignment runAlignment;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;

  const AnimatedStaggeredWrap({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 375),
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Wrap(
        direction: direction,
        alignment: alignment,
        spacing: spacing,
        runAlignment: runAlignment,
        runSpacing: runSpacing,
        crossAxisAlignment: crossAxisAlignment,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (widget) => ScaleAnimation(
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

/// Single animated item with multiple animation effects
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final AnimationType animationType;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 375),
    this.animationType = AnimationType.slideUp,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: _buildAnimation(),
    );
  }

  Widget _buildAnimation() {
    switch (animationType) {
      case AnimationType.slideUp:
        return SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(child: child),
        );
      case AnimationType.slideDown:
        return SlideAnimation(
          verticalOffset: -50.0,
          child: FadeInAnimation(child: child),
        );
      case AnimationType.slideLeft:
        return SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(child: child),
        );
      case AnimationType.slideRight:
        return SlideAnimation(
          horizontalOffset: -50.0,
          child: FadeInAnimation(child: child),
        );
      case AnimationType.scale:
        return ScaleAnimation(
          child: FadeInAnimation(child: child),
        );
      case AnimationType.fadeIn:
        return FadeInAnimation(child: child);
      case AnimationType.flip:
        return FlipAnimation(
          child: FadeInAnimation(child: child),
        );
    }
  }
}

/// Animation types for list items
enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scale,
  fadeIn,
  flip,
}

/// Animated sliver list wrapper
class AnimatedSliverList extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;

  const AnimatedSliverList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: duration,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: children[index],
              ),
            ),
          );
        },
        childCount: children.length,
      ),
    );
  }
}

/// Animated sliver grid wrapper
class AnimatedSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Duration duration;

  const AnimatedSliverGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: duration,
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: children[index],
              ),
            ),
          );
        },
        childCount: children.length,
      ),
    );
  }
}
