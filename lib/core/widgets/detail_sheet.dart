import 'package:flutter/material.dart';

import 'dialogs.dart';


class DetailRow {
  const DetailRow(this.icon, this.label, this.value, {this.color, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  
  final VoidCallback? onTap;
}



class DetailSheet extends StatelessWidget {
  const DetailSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    this.subtitle,
    this.highlight,
    this.highlightColor,
    this.badge,
    this.note,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  
  final String? highlight;
  final Color? highlightColor;
  final Widget? badge;
  final String? note;
  final List<DetailRow> rows;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: title, subtitle: subtitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    if (highlight != null)
                      Expanded(
                        child: Text(
                          highlight!,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: highlightColor,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    ?badge,
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Icon(rows[i].icon, color: rows[i].color),
                          title: Text(
                            rows[i].value,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: rows[i].onTap != null
                                  ? scheme.primary
                                  : rows[i].color,
                            ),
                          ),
                          subtitle: Text(rows[i].label),
                          trailing: rows[i].onTap == null
                              ? null
                              : const Icon(Icons.chevron_right),
                          onTap: rows[i].onTap,
                        ),
                      ],
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(note!),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          )
        else
          const SizedBox(height: 24),
      ],
    );
  }
}
