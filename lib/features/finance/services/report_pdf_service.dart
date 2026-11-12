import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../../data/models/finance.dart';





class ReportPdfService {
  const ReportPdfService();

  static const _purple = PdfColor.fromInt(0xFF7A1FD1);
  static const _green = PdfColor.fromInt(0xFF1E9E6A);
  static const _red = PdfColor.fromInt(0xFFD93A4A);
  static const _grey = PdfColor.fromInt(0xFF6B6774);

  String fileName(DateTime month) =>
      'relatorio_abracapets_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf';

  Future<Uint8List> build({
    required DateTime month,
    required List<Donation> donations,
    required List<Expense> expenses,
    required Map<ExpenseCategory, double> categoryTotals,
    required bool includeDonorNames,
    required String Function(String animalId) animalName,
    required String generatedBy,
  }) async {
    final totalIn = donations.fold<double>(0, (s, d) => s + d.amount);
    final totalOut = expenses.fold<double>(0, (s, e) => s + e.amount);
    final balance = totalIn - totalOut;
    final missingInvoice = expenses.where((e) => !e.hasInvoice).length;
    final categories = categoryTotals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document(
      title: 'Relatório financeiro ${Fmt.monthYear(month)}',
      author: 'AbraçaPets',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text('AbraçaPets · ${Fmt.monthYear(month)}',
                style: const pw.TextStyle(color: _grey, fontSize: 9)),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gerado em ${Fmt.date(DateTime.now())} por $generatedBy',
              style: const pw.TextStyle(color: _grey, fontSize: 9),
            ),
            pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: const pw.TextStyle(color: _grey, fontSize: 9)),
          ],
        ),
        build: (ctx) => [
          
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: const pw.BoxDecoration(
              color: _purple,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AbraçaPets',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Relatório financeiro · ${Fmt.monthYear(month)}',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 13)),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _summary('Entradas', Fmt.currency(totalIn), _green),
              pw.SizedBox(width: 10),
              _summary('Saídas', Fmt.currency(totalOut), _red),
              pw.SizedBox(width: 10),
              _summary('Saldo', Fmt.currency(balance),
                  balance >= 0 ? _green : _red),
            ],
          ),
          if (missingInvoice > 0) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Atenção: $missingInvoice despesa(s) sem nota fiscal anexada '
              '(marcadas com * na tabela).',
              style: const pw.TextStyle(color: _red, fontSize: 10),
            ),
          ],
          _title('Despesas por categoria'),
          if (categories.isEmpty)
            pw.Text('Nenhuma despesa no período.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Categoria', 'Valor', '% do total'],
              data: [
                for (final c in categories)
                  [
                    c.key.label,
                    Fmt.currency(c.value),
                    '${(c.value / totalOut * 100).toStringAsFixed(1)}%',
                  ],
              ],
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: _purple),
              cellAlignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
            ),
          _title('Doações recebidas (${donations.length})'),
          if (donations.isEmpty)
            pw.Text('Nenhuma doação no período.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Doador', 'Meio', 'Valor'],
              data: [
                for (final d in donations)
                  [
                    Fmt.date(d.date),
                    d.campaign != null
                        ? 'Campanha: ${d.campaign}'
                        : includeDonorNames
                            ? d.displayName
                            : (d.donorName == null ? 'Anônimo' : 'Doador(a)'),
                    d.method.label,
                    Fmt.currency(d.amount),
                  ],
              ],
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: _green),
              cellAlignments: {3: pw.Alignment.centerRight},
            ),
          _title('Despesas (${expenses.length})'),
          if (expenses.isEmpty)
            pw.Text('Nenhuma despesa no período.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Descrição', 'Categoria', 'Pet', 'Valor'],
              data: [
                for (final e in expenses)
                  [
                    Fmt.date(e.date),
                    '${e.description}${e.hasInvoice ? '' : ' *'}',
                    e.category.label,
                    e.animalId == null ? 'Geral' : animalName(e.animalId!),
                    Fmt.currency(e.amount),
                  ],
              ],
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: _red),
              cellAlignments: {4: pw.Alignment.centerRight},
            ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _title(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: _purple)),
      );

  pw.Widget _summary(String label, String value, PdfColor color) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(color: _grey, fontSize: 10)),
              pw.Text(value,
                  style: pw.TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );
}
