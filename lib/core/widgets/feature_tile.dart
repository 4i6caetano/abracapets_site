import 'package:flutter/material.dart';


class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    this.caption,
    this.badge,
    this.color,
    this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final String? badge;
  final Color? color;
  final VoidCallback? onTap;

  
  final bool filled;

  
  static SliverGridDelegate gridDelegate({
    double maxExtent = 210,
    double height = 128,
  }) => SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxExtent,
    mainAxisExtent: height,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tint = color ?? scheme.primary;
    final fg = filled ? Colors.white : scheme.onSurface;

    return Material(
      color: filled ? tint : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: filled
                ? null
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: filled
                          ? Colors.white.withValues(alpha: 0.18)
                          : tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: filled ? Colors.white : tint),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: filled ? Colors.white : tint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: textTheme.labelSmall?.copyWith(
                          color: filled ? tint : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fg,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (caption != null)
                        Text(
                          caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: filled
                                ? Colors.white.withValues(alpha: 0.8)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
