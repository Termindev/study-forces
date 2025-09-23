import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/subject.dart';
import '../../models/rank.dart';
import '../../utils/rank_utils.dart';
import '../common/rank_badge.dart';
import '../../constants/app_constants.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback? onStudyTap;
  final VoidCallback? onProblemTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onStudyTap,
    this.onProblemTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  // Helper method to get the highest rank between study and problem ranks
  Rank? _getHighestRank(Rank? studyRank, Rank? problemRank) {
    if (studyRank == null && problemRank == null) return null;
    if (studyRank == null) return problemRank;
    if (problemRank == null) return studyRank;

    // Return the rank with higher required rating
    return studyRank.requiredRating >= problemRank.requiredRating
        ? studyRank
        : problemRank;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyRank = RankUtils.getCurrentRank(
      subject.studyRating,
      subject.ranks,
    );
    final problemRank = RankUtils.getCurrentRank(
      subject.problemRating,
      subject.ranks,
    );

    // Determine primary rank color and glow
    final rankColor = studyRank?.color ?? problemRank?.color ?? '#FF6200EA';
    final shouldGlow = studyRank?.glow ?? problemRank?.glow ?? false;
    final color = Color(int.parse(rankColor.replaceFirst('#', '0x')));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Slidable(
        startActionPane: subject.studyEnabled && onStudyTap != null
            ? ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => onStudyTap!(),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.book,
                    label: 'Study',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radiusL),
                      bottomLeft: Radius.circular(AppConstants.radiusL),
                    ),
                  ),
                ],
              )
            : null,
        endActionPane: subject.problemEnabled && onProblemTap != null
            ? ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => onProblemTap!(),
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    icon: Icons.psychology,
                    label: 'Problem',
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppConstants.radiusL),
                      bottomRight: Radius.circular(AppConstants.radiusL),
                    ),
                  ),
                ],
              )
            : null,
        child: Card(
          color: color.withOpacity(0.1),
          elevation: shouldGlow
              ? AppConstants.elevationXL
              : AppConstants.elevationS,
          shadowColor: shouldGlow ? color : null,
          shape: shouldGlow
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  side: BorderSide(color: color, width: 2),
                )
              : null,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject name at the top
                  Text(
                    subject.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: shouldGlow ? color : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.spacingS),

                  // Description or "No description" text
                  Text(
                    subject.description.isNotEmpty
                        ? subject.description
                        : 'No description',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontStyle: subject.description.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.spacingM),

                  // Rating display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (subject.studyEnabled) ...[
                        Column(
                          children: [
                            Text('Study', style: theme.textTheme.labelSmall),
                            Text(
                              subject.studyRating.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (subject.problemEnabled) ...[
                        Column(
                          children: [
                            Text('Problem', style: theme.textTheme.labelSmall),
                            Text(
                              subject.problemRating.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Ranks display - show only the highest rank to avoid overflow
                  if (studyRank != null || problemRank != null) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Builder(
                      builder: (context) {
                        final highestRank = _getHighestRank(
                          studyRank,
                          problemRank,
                        );
                        if (highestRank == null) return const SizedBox.shrink();
                        return RankBadge(
                          rank: highestRank,
                          isCurrent: true,
                          size: 24.0,
                        );
                      },
                    ),
                  ],

                  // Stats row
                  const SizedBox(height: AppConstants.spacingM),
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingXS,
                    children: [
                      if (subject.studyEnabled) ...[
                        _buildStatChip(
                          context,
                          Icons.book,
                          '${subject.studySessions.length} sessions',
                          theme.colorScheme.primary,
                        ),
                        _buildStatChip(
                          context,
                          Icons.local_fire_department,
                          '${subject.calculateStudyStreak()} streak',
                          theme.colorScheme.primary,
                        ),
                      ],
                      if (subject.problemEnabled) ...[
                        _buildStatChip(
                          context,
                          Icons.psychology,
                          '${subject.problemSessions.length} sessions',
                          theme.colorScheme.secondary,
                        ),
                        _buildStatChip(
                          context,
                          Icons.local_fire_department,
                          '${subject.calculateProblemStreak()} streak',
                          theme.colorScheme.secondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppConstants.iconS, color: color),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
