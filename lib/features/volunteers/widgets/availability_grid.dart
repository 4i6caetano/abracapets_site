import 'package:flutter/material.dart';

import '../../../data/models/volunteer.dart';


class AvailabilityGrid extends StatelessWidget {
  const AvailabilityGrid({
    super.key,
    required this.availability,
    this.onToggle,
  });

  final Map<Weekday, Set<ShiftPeriod>> availability;
  final void Function(Weekday day, ShiftPeriod period)? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 56),
            for (final d in Weekday.values)
              Expanded(
                child: Center(child: Text(d.short, style: labelStyle)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final p in ShiftPeriod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text(p.label, style: labelStyle)),
                for (final d in Weekday.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _Cell(
                        selected: availability[d]?.contains(p) ?? false,
                        onTap: onToggle == null ? null : () => onToggle!(d, p),
                        tooltip: '${d.long} – ${p.label.toLowerCase()}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.selected, required this.tooltip, this.onTap});

  final bool selected;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 30,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: selected
              ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
              : null,
        ),
      ),
    );
  }
}
