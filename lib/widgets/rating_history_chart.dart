import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/rating_log.dart';

class RatingHistoryChart extends StatelessWidget {
  final List<RatingLog> ratingHistory;
  final String title;
  final Color color;
  final int maxRating;

  const RatingHistoryChart({
    super.key,
    required this.ratingHistory,
    required this.title,
    required this.color,
    required this.maxRating,
  });

  @override
  Widget build(BuildContext context) {
    if (ratingHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No rating history available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by date
    final sortedHistory = List<RatingLog>.from(ratingHistory)
      ..sort((a, b) => a.when.compareTo(b.when));

    // Prepare data points for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedHistory[i].rating.toDouble()));
    }

    // Calculate min and max values for better scaling with more padding
    final minRating = sortedHistory
        .map((log) => log.rating)
        .reduce((a, b) => a < b ? a : b);
    final maxRatingValue = sortedHistory
        .map((log) => log.rating)
        .reduce((a, b) => a > b ? a : b);

    // Add more padding to prevent ratings from being too close together
    final ratingRange = maxRatingValue - minRating;
    final padding = ratingRange * 0.4; // 40% padding (increased from 30%)
    final chartMin = (minRating - padding).clamp(0.0, double.infinity);
    final chartMax = (maxRatingValue + padding).clamp(
      0.0,
      maxRating.toDouble(),
    );

    // Ensure there's always space above the highest rating
    final minChartMax =
        maxRatingValue +
        (ratingRange * 0.2); // At least 20% above highest (increased from 10%)
    final finalChartMax = max(chartMax, minChartMax);

    // Ensure we have a minimum range to prevent zero interval
    final chartRange = finalChartMax - chartMin;
    final safeChartMin = chartRange > 0 ? chartMin : max(0.0, minRating - 10);
    final safeChartMax = chartRange > 0 ? finalChartMax : minRating + 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300, // Increased height from 200 to 300
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (sortedHistory.length * 60.0).clamp(
                    400.0,
                    double.infinity,
                  ), // Minimum 400px, 60px per data point
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      height:
                          400, // Make chart taller to enable vertical scrolling
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: max(
                              1.0,
                              (safeChartMax - safeChartMin) / 5,
                            ),
                            verticalInterval: (sortedHistory.length > 10)
                                ? (sortedHistory.length / 8).ceil().toDouble()
                                : 1, // Fewer vertical lines when many data points
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (sortedHistory.length > 10)
                                    ? (sortedHistory.length / 8)
                                          .ceil()
                                          .toDouble()
                                    : 1, // Show fewer labels when many data points
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < sortedHistory.length) {
                                    final date =
                                        sortedHistory[value.toInt()].when;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: max(
                                  1.0,
                                  (safeChartMax - safeChartMin) / 5,
                                ),
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          minX: 0,
                          maxX: (sortedHistory.length - 1).toDouble(),
                          minY: safeChartMin.toDouble(),
                          maxY: safeChartMax.toDouble(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: color,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: color,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: color.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${sortedHistory.last.rating}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                if (sortedHistory.length > 1)
                  Text(
                    'Change: ${sortedHistory.last.rating - sortedHistory.first.rating > 0 ? '+' : ''}${sortedHistory.last.rating - sortedHistory.first.rating}',
                    style: TextStyle(
                      color:
                          sortedHistory.last.rating >=
                              sortedHistory.first.rating
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
