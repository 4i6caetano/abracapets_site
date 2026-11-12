import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/volunteer.dart';

class VolunteerCard extends StatelessWidget {
  const VolunteerCard({
    super.key,
    required this.volunteer,
    this.onTap,
    this.badge,
    this.highlightSkill,
  });

  final Volunteer volunteer;
  final VoidCallback? onTap;
  final Widget? badge;
  final VolunteerSkill? highlightSkill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: volunteer.name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            volunteer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ?badge,
                      ],
                    ),
                    Text(
                      volunteer.availabilitySummary,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in volunteer.skills)
                          StatusBadge(
                            icon: s.icon,
                            label: s.label,
                            color: s == highlightSkill
                                ? AppColors.accentDark
                                : scheme.primary,
                            solid: s == highlightSkill,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'WhatsApp',
                onPressed: () => showMessage(
                  context,
                  'Abrindo WhatsApp de ${volunteer.name} (${volunteer.whatsapp})',
                  icon: Icons.chat,
                ),
                icon: const Icon(Icons.chat_outlined, color: AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
