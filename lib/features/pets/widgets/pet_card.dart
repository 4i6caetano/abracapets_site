import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../data/models/animal.dart';

class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.animal, this.onTap});

  final Animal animal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'pet-photo-${animal.id}',
                    child: NetworkPhoto(
                      url: animal.mainPhotoUrl,
                      fallbackIcon: animal.species.icon,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: StatusBadge(
                      label: animal.status.label,
                      color: animal.status.color,
                      solid: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        animal.sex == Sex.male ? Icons.male : Icons.female,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  Text(
                    '${animal.breed} · ${Fmt.age(animal.birthDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _HealthDot(
                        ok: animal.vaccinated,
                        icon: Icons.vaccines_outlined,
                        tooltip: animal.vaccinated
                            ? 'Vacinado'
                            : 'Não vacinado',
                      ),
                      const SizedBox(width: 6),
                      _HealthDot(
                        ok: animal.castrated,
                        icon: Icons.content_cut,
                        tooltip: animal.castrated ? 'Castrado' : 'Não castrado',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({
    required this.ok,
    required this.icon,
    required this.tooltip,
  });

  final bool ok;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? const Color(0xFF1E9E6A) : scheme.outline;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
