import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';


Future<DateTime?> showMonthPicker(BuildContext context, DateTime initial) =>
    showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initial: initial),
    );

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});

  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;
  final _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            tooltip: 'Ano anterior',
            onPressed: _year > 2020 ? () => setState(() => _year--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Próximo ano',
            onPressed: _year < _now.year ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            for (var m = 1; m <= 12; m++)
              Builder(
                builder: (context) {
                  final enabled = DateTime(_year, m)
                      .isBefore(DateTime(_now.year, _now.month + 1));
                  final selected = widget.initial.year == _year &&
                      widget.initial.month == m;
                  return FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      backgroundColor: selected ? scheme.primary : null,
                      foregroundColor: selected ? scheme.onPrimary : null,
                    ),
                    onPressed: enabled
                        ? () => Navigator.pop(context, DateTime(_year, m))
                        : null,
                    child: Text(Fmt.monthName(m).substring(0, 3)),
                  );
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, DateTime(_now.year, _now.month)),
          child: const Text('Mês atual'),
        ),
      ],
    );
  }
}
