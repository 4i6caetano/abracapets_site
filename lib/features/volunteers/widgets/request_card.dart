import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/request.dart';


class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.restricted,
    required this.onApprove,
    required this.onReject,
    this.animalName,
    this.onOpenProfile,
    this.onTap,
  });

  final AppRequest request;
  final bool restricted;
  final String? animalName;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onOpenProfile;

  
  final VoidCallback? onTap;

  Color get _scoreColor => request.screeningScore >= 0.7
      ? AppColors.success
      : request.screeningScore >= 0.4
      ? AppColors.warning
      : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pending = request.status == RequestStatus.pending;

    final String headline = switch (request.type) {
      RequestType.adoption => 'Quer adotar: ${animalName ?? '—'}',
      RequestType.volunteering => 'Quer ser voluntário(a)',
      RequestType.report => 'Denúncia recebida',
    };

    return Card(
      shape: restricted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.danger, width: 2),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (restricted) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      request.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (restricted)
                    const StatusBadge(
                      label: 'RESTRITA',
                      color: AppColors.danger,
                      solid: true,
                    )
                  else if (!pending)
                    StatusBadge(
                      label: request.status == RequestStatus.approved
                          ? 'Aprovada'
                          : 'Recusada',
                      color: request.status == RequestStatus.approved
                          ? AppColors.success
                          : scheme.outline,
                    )
                  else
                    Text(
                      Fmt.relative(request.date),
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                headline,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                restricted ? 'Pessoa na lista de restrição' : request.summary,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              if (request.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in request.skills)
                      StatusBadge(label: s, color: scheme.primary),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Pré-triagem', style: textTheme.labelMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: request.screeningScore,
                      minHeight: 8,
                      color: _scoreColor,
                      backgroundColor: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(request.screeningScore * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
              if (pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: onOpenProfile ?? onReject,
                        child: Text(
                          onOpenProfile != null
                              ? (restricted ? 'Ver motivo' : 'Ver ficha')
                              : 'Recusar',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: restricted ? AppColors.danger : null,
                        ),
                        onPressed: restricted ? onReject : onApprove,
                        child: Text(
                          restricted
                              ? 'Recusar'
                              : request.type == RequestType.report
                              ? 'Atender'
                              : 'Aprovar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
