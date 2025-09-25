import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../constants/app_constants.dart';

class SessionListItem extends StatelessWidget {
  final dynamic session; // Can be StudySession or ProblemSession
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isStudySession;

  const SessionListItem({
    super.key,
    required this.session,
    this.onTap,
    this.onEdit,
    this.onDelete,
    required this.isStudySession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingXS,
      ),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (onEdit != null)
              SlidableAction(
                onPressed: (_) => onEdit!(),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                borderRadius: BorderRadius.zero,
              ),
            if (onDelete != null)
              SlidableAction(
                onPressed: (_) => onDelete!(),
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: BorderRadius.zero,
              ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isStudySession
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Icon(
                      isStudySession ? Icons.book : Icons.psychology,
                      color: isStudySession
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      size: AppConstants.iconM,
                    ),
                  ),

                  const SizedBox(width: AppConstants.spacingM),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSessionTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          _getSessionSubtitle(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          _formatDate(session.when),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Performance indicator
                  if (isStudySession)
                    _buildPerformanceIndicator(
                      context,
                      session.performance,
                      theme.colorScheme.primary,
                    )
                  else
                    _buildPerformanceIndicator(
                      context,
                      session.performance,
                      theme.colorScheme.secondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionTitle() {
    if (isStudySession) {
      return 'Study Session';
    } else {
      return 'Problem Session';
    }
  }

  String _getSessionSubtitle() {
    if (isStudySession) {
      return '${session.units} units completed';
    } else {
      return '${session.problemsCorrect}/${session.problemsAttempted} problems solved';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPerformanceIndicator(
    BuildContext context,
    double performance,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getPerformanceColor(performance).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: _getPerformanceColor(performance).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPerformanceIcon(performance),
            size: AppConstants.iconS,
            color: _getPerformanceColor(performance),
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            '${(performance * 100).toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getPerformanceColor(performance),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double performance) {
    if (performance >= 0.8) {
      return Colors.green;
    } else if (performance >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getPerformanceIcon(double performance) {
    if (performance >= 0.8) {
      return Icons.trending_up;
    } else if (performance >= 0.6) {
      return Icons.trending_flat;
    } else {
      return Icons.trending_down;
    }
  }
}
