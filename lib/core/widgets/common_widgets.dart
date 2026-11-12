import 'package:flutter/material.dart';

import '../utils/formatters.dart';


class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
    this.onFilterTap,
    this.filterCount = 0,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final VoidCallback? onFilterTap;
  final int filterCount;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (v) {
              widget.onChanged(v);
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: const Icon(Icons.search),
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: widget.filterCount > 0,
            label: Text('${widget.filterCount}'),
            backgroundColor: scheme.secondary,
            child: IconButton.filledTonal(
              tooltip: 'Filtros',
              onPressed: widget.onFilterTap,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ],
    );
  }
}


class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.solid = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool solid;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: solid ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.color,
  });

  final String name;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = [
      scheme.primary,
      scheme.secondary,
      const Color(0xFF16A394),
      const Color(0xFF3C7BEA),
      const Color(0xFFE2478B),
    ];
    final c = color ?? palette[name.hashCode.abs() % palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withValues(alpha: 0.15),
      child: Text(
        Fmt.initials(name),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, size: 34, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}


class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class NavCard extends StatelessWidget {
  const NavCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Card(
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tint),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}



class ChipStrip extends StatefulWidget {
  const ChipStrip({super.key, required this.children});

  final List<Widget> children;

  @override
  State<ChipStrip> createState() => _ChipStripState();
}

class _ChipStripState extends State<ChipStrip> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thickness: 3,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            for (final c in widget.children)
              Padding(padding: const EdgeInsets.only(right: 8), child: c),
          ],
        ),
      ),
    );
  }
}


class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        ),
        child: Text(value == null ? 'Selecionar' : Fmt.date(value!)),
      ),
    );
  }
}



class SliverAdaptiveGrid extends StatelessWidget {
  const SliverAdaptiveGrid({
    super.key,
    required this.children,
    this.maxItemWidth = 520,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double maxItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          var cols = ((w + spacing) / (maxItemWidth + spacing)).ceil();
          if (cols < 1) cols = 1;
          final itemWidth = (w - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final c in children) SizedBox(width: itemWidth, child: c),
            ],
          );
        },
      ),
    );
  }
}
