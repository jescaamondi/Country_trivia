import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_trivia/core/constants/api_constants.dart';
import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Renders a country flag from FlagCDN with placeholder and error states.
///
/// Cached on disk so replaying a country later is instant and works offline
/// once seen.
class FlagImage extends StatelessWidget {
  const FlagImage({super.key, required this.isoCode, this.borderRadius = 12});

  final String isoCode;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = FlagConstants.imageUrl(isoCode);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, _) => const _FlagPlaceholder(),
          errorWidget: (context, _, _) => const _FlagError(),
        ),
      ),
    );
  }
}

class _FlagPlaceholder extends StatelessWidget {
  const _FlagPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _FlagError extends StatelessWidget {
  const _FlagError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
            SizedBox(height: 6),
            Text(
              'Flag unavailable',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
