import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';







class ReportPreviewPage extends StatelessWidget {
  const ReportPreviewPage({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.title,
  });

  final Uint8List bytes;
  final String fileName;
  final String title;

  Future<void> _download() =>
      Printing.sharePdf(bytes: bytes, filename: fileName);

  Future<void> _print() =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Imprimir',
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Baixar / compartilhar PDF',
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const CircularProgressIndicator(),
        onError: (context, error) => _PreviewUnavailable(
          fileName: fileName,
          sizeKb: (bytes.lengthInBytes / 1024).ceil(),
          onDownload: _download,
          onPrint: _print,
        ),
      ),
    );
  }
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable({
    required this.fileName,
    required this.sizeKb,
    required this.onDownload,
    required this.onPrint,
  });

  final String fileName;
  final int sizeKb;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.picture_as_pdf_outlined,
                    size: 34, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF gerado',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '$fileName · $sizeKb KB\n'
                'A pré-visualização não está disponível neste navegador, '
                'mas você pode baixar ou imprimir o relatório.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Baixar PDF'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Imprimir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
