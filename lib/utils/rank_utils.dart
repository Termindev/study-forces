import '../models/rank.dart';

class RankUtils {
  /// Get the current rank based on rating and available ranks
  static Rank? getCurrentRank(int rating, List<Rank> ranks) {
    if (ranks.isEmpty) return null;

    // Sort ranks by required rating (ascending)
    final sortedRanks = List<Rank>.from(ranks)
      ..sort((a, b) => a.requiredRating.compareTo(b.requiredRating));

    // Find the highest rank that the user has achieved
    Rank? currentRank;
    for (final rank in sortedRanks) {
      if (rating >= rank.requiredRating) {
        currentRank = rank;
      } else {
        break;
      }
    }

    return currentRank;
  }

  /// Get the next rank the user can achieve
  static Rank? getNextRank(int rating, List<Rank> ranks) {
    if (ranks.isEmpty) return null;

    // Sort ranks by required rating (ascending)
    final sortedRanks = List<Rank>.from(ranks)
      ..sort((a, b) => a.requiredRating.compareTo(b.requiredRating));

    // Find the first rank that the user hasn't achieved yet
    for (final rank in sortedRanks) {
      if (rating < rank.requiredRating) {
        return rank;
      }
    }

    return null; // User has achieved all ranks
  }

  /// Get progress towards the next rank (0.0 to 1.0)
  static double getProgressToNextRank(int rating, List<Rank> ranks) {
    final currentRank = getCurrentRank(rating, ranks);
    final nextRank = getNextRank(rating, ranks);

    if (currentRank == null || nextRank == null) return 0.0;

    final currentRating = currentRank.requiredRating;
    final nextRating = nextRank.requiredRating;

    if (nextRating <= currentRating) return 1.0;

    return (rating - currentRating) / (nextRating - currentRating);
  }
}
