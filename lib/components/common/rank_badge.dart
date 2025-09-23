import 'package:flutter/material.dart';
import '../../models/rank.dart';
import '../../constants/app_constants.dart';

class RankBadge extends StatelessWidget {
  final Rank rank;
  final bool isCurrent;
  final bool showLabel;
  final double size;
  final VoidCallback? onTap;

  const RankBadge({
    super.key,
    required this.rank,
    this.isCurrent = false,
    this.showLabel = true,
    this.size = 32.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(rank.color.replaceFirst('#', '0x')));

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: rank.glow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
        border: isCurrent
            ? Border.all(color: theme.colorScheme.onSurface, width: 2)
            : null,
      ),
      child: Icon(Icons.star, color: Colors.white, size: size * 0.6),
    );

    if (onTap != null) {
      badge = GestureDetector(onTap: onTap, child: badge);
    }

    if (!showLabel) {
      return badge;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: AppConstants.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rank.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isCurrent ? color : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCurrent)
              Text(
                'CURRENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

