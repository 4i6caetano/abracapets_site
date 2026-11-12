import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';








class AppNestedScaffold extends StatelessWidget {
  const AppNestedScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.headerContent,
    this.background,
    this.headerHeight = 120,
    this.bottom,
    this.bottomHeight = 0,
    this.actions,
    this.slivers,
    this.tabViews,
    this.floatingActionButton,
    this.bottomBar,
    this.showBack = true,
    this.showExpandedTitle = true,
    this.maxContentWidth = Breakpoints.maxContent,
  }) : assert(slivers != null || tabViews != null);

  final String title;
  final String? subtitle;

  
  final Widget? headerContent;

  
  final Widget? background;

  
  final double headerHeight;

  
  final Widget? bottom;
  final double bottomHeight;
  final List<Widget>? actions;
  final List<Widget>? slivers;
  final List<List<Widget>>? tabViews;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool showBack;
  final bool showExpandedTitle;
  final double maxContentWidth;

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    final stripHeight = bottom == null ? 24.0 : bottomHeight + 22;

    return Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = horizontalPaddingFor(
            constraints.maxWidth,
            maxContent: maxContentWidth,
          );

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leading: canPop
                      ? const BackButton(color: Colors.white)
                      : null,
                  actions: [...?actions, const SizedBox(width: 4)],
                  iconTheme: const IconThemeData(color: Colors.white),
                  actionsIconTheme: const IconThemeData(color: Colors.white),
                  backgroundColor: AppColors.primary,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  expandedHeight: kToolbarHeight + headerHeight + stripHeight,
                  flexibleSpace: _HeaderBackground(
                    title: title,
                    subtitle: subtitle,
                    headerContent: headerContent,
                    background: background,
                    stripHeight: stripHeight,
                    horizontalPadding: pad,
                    hasLeading: canPop,
                    showExpandedTitle: showExpandedTitle,
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(stripHeight),
                    child: Container(
                      height: stripHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_radius),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
                      alignment: Alignment.topCenter,
                      child: bottom == null
                          ? Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : SizedBox(height: bottomHeight, child: bottom),
                    ),
                  ),
                ),
              ),
            ],
            body: tabViews != null
                ? TabBarView(
                    children: [
                      for (var i = 0; i < tabViews!.length; i++)
                        _InnerScroll(
                          storageKey: '$title-tab-$i',
                          slivers: tabViews![i],
                          horizontalPadding: pad,
                        ),
                    ],
                  )
                : _InnerScroll(
                    storageKey: title,
                    slivers: slivers!,
                    horizontalPadding: pad,
                  ),
          );
        },
      ),
    );
  }
}

class _InnerScroll extends StatelessWidget {
  const _InnerScroll({
    required this.storageKey,
    required this.slivers,
    required this.horizontalPadding,
  });

  final String storageKey;
  final List<Widget> slivers;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) => CustomScrollView(
          key: PageStorageKey<String>(storageKey),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                104,
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.title,
    required this.subtitle,
    required this.headerContent,
    required this.background,
    required this.stripHeight,
    required this.horizontalPadding,
    required this.hasLeading,
    required this.showExpandedTitle,
  });

  final String title;
  final String? subtitle;
  final Widget? headerContent;
  final Widget? background;
  final double stripHeight;
  final double horizontalPadding;
  final bool hasLeading;
  final bool showExpandedTitle;

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final topPadding = MediaQuery.paddingOf(context).top;
    var t = 1.0;
    if (settings != null && settings.maxExtent > settings.minExtent) {
      t =
          ((settings.currentExtent - settings.minExtent) /
                  (settings.maxExtent - settings.minExtent))
              .clamp(0.0, 1.0);
    }
    final expandedOpacity = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
    final collapsedOpacity = ((0.45 - t) / 0.45).clamp(0.0, 1.0);
    final textTheme = Theme.of(context).textTheme;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          
          if (background != null)
            background!
          else
            const ColoredBox(color: AppColors.primary),
          if (background != null)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35 + 0.4 * (1 - t)),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          
          Positioned(
            top: topPadding,
            left: hasLeading ? 56 : horizontalPadding,
            right: 120,
            height: kToolbarHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: collapsedOpacity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: stripHeight + 16,
            child: IgnorePointer(
              ignoring: expandedOpacity < 0.6,
              child: Opacity(
                opacity: expandedOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showExpandedTitle) ...[
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                    if (headerContent != null) ...[
                      if (showExpandedTitle) const SizedBox(height: 16),
                      headerContent!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
