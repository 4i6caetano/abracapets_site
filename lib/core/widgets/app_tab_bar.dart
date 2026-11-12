import 'package:flutter/material.dart';






class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    this.isScrollable = false,
  });

  static const height = 54.0;

  final List<Widget> tabs;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(40),
      ),
      child: TabBar(
        tabs: tabs,
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelPadding: const EdgeInsets.symmetric(horizontal: 18),
        splashBorderRadius: BorderRadius.circular(40),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
