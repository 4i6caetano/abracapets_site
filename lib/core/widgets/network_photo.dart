import 'package:flutter/material.dart';

import '../theme/app_colors.dart';


class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({
    super.key,
    required this.url,
    this.fallbackIcon = Icons.pets,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Fallback(icon: fallbackIcon);
    final image = url == null
        ? placeholder
        : Image.network(
            url!,
            
            
            key: ValueKey(url),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            frameBuilder: (context, child, frame, sync) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: frame == null && !sync
                  ? _Fallback(icon: fallbackIcon, loading: true)
                  : child,
            ),
            errorBuilder: (_, _, _) => placeholder,
          );
    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon, this.loading = false});

  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.55),
            AppColors.accent.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}
