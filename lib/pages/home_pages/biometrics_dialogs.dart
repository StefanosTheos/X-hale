import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/home_pages/biometrics_data.dart';
import 'package:smoking/pages/home_pages/chatbot_page.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/user_provider.dart';

/// Dialogs and chart helpers extracted verbatim from `biometrics.dart`.
/// Everything here is pure (takes its arguments, touches no State), which is
/// why these were safe to pull out without changing appearance or behaviour.

double getMaxYForMetric(String metric, List<DailyValue> values) {
  double maxValue =
      values.map((v) => v.value).reduce((a, b) => a > b ? a : b).toDouble();

  switch (metric) {
    case "Heart Rate":
      return 90.0;
    case "HRV":
      return 80.0;
    case "Steps":
      return 14000.0;
    case "Sleep":
      return 9.0;
    case "Stress Level":
      return 100.0;
    case "Weight / BMI":
      return 80.0;
    default:
      return maxValue * 1.2;
  }
}

double getIntervalForMetric(String metric) {
  switch (metric) {
    case "Heart Rate":
      return 10;
    case "Blood Oxygen":
      return 20;
    case "Steps":
      return 2000;
    case "Sleep":
      return 1;
    case "Stress Level":
      return 25;
    case "Weight / BMI":
      return 10;
    default:
      return 5;
  }
}

String getQualityForValue(String metric, num value) {
  if (metric == "Sleep") {
    if (value >= 8.0) return "Excellent (8h+)";
    if (value >= 7.0) return "Good (7h-8h)";
    if (value >= 6.0) return "Fair (6h-7h)";
    return "Poor (<6h)";
  } else if (metric == "Heart Rate") {
    if (value <= 50) return "Very Low (<60)";
    if (value <= 60) return "Low (60-70)";
    if (value <= 70) return "Normal (70-80)";
    if (value <= 80) return "Normal (70-80)";
    if (value <= 90) return "Elevated (80-100)";
    if (value <= 100) return "Elevated (80-100)";
    return "High (>100)";
  } else if (metric == "Blood Oxygen") {
    if (value >= 95) return "Normal (95-100%)";
    if (value >= 90) return "Lower than normal (90-94%)";
    return "Seek Medical Advice (<90%)";
  } else if (metric == "Stress Level") {
    if (value <= 25) return "Relaxed (0-25%)";
    if (value <= 50) return "Low (25-50%)";
    if (value <= 75) return "Moderate (50-75%)";
    return "High (75-100%)";
  } else if (metric == "Steps") {
    if (value >= 10000) return "Excellent (10k+)";
    if (value >= 8000) return "Good (8k-10k)";
    if (value >= 6000) return "Fair (6k-8k)";
    if (value >= 4000) return "Poor (4k-6k)";
    return "Very Poor (<4k)";
  } else if (metric == "Weight / BMI") {
    final height = 1.75;
    final bmi = value / (height * height);

    String healthStatus;
    if (bmi < 18.5) {
      healthStatus = "Underweight";
    } else if (bmi < 25) {
      healthStatus = "Healthy";
    } else if (bmi < 30) {
      healthStatus = "Overweight";
    } else if (bmi < 40) {
      healthStatus = "Obese";
    } else {
      healthStatus = "Morbidly Obese";
    }

    return "${value.toStringAsFixed(1)} kg - BMI ${bmi.toStringAsFixed(1)} ($healthStatus)";
  }
  return "";
}

void showDailyDetails(
  BuildContext context,
  DailyValue dailyValue,
  Map<String, dynamic> metric,
  Color cardColor,
  bool isDark,
) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: isDark ? AppThemes.darkCardColor : cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  (metric["color"] as Color).withAlpha((0.15 * 255).round()),
              child: Icon(
                metric["icon"] as IconData? ?? Icons.insights,
                color: metric["color"] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${metric["title"]} - ${dailyValue.day}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppThemes.darkTextColor : AppThemes.lightSubtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Divider(
              thickness: 1,
              color: isDark ? Colors.white24 : Colors.black12,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 12),
            Text(
              dailyValue.details,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: metric["color"] as Color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showInfoDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> metric,
  Color cardColor,
  bool isDark,
) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: isDark ? AppThemes.darkCardColor : cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 40,
              color: metric["color"] as Color,
            ),
            const SizedBox(height: 12),
            Text(
              'Did you know?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppThemes.darkTextColor : AppThemes.lightSubtitleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              metric["title"] == "Steps"
                  ? 'Your ${metric["title"]} are improving with every smoke-free day! Want to understand how?'
                  : 'Your ${metric["title"]} is improving with every smoke-free day! Want to understand how?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : Colors.grey.shade700,
                        side: BorderSide(
                          color: metric["color"] as Color,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          fontSize: 16,
                          color: metric["color"] as Color,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prompt =
                            'I have read about the metric "${metric['title']}": '
                            '"${metricContext[metric['title']] ?? metric['description']}". '
                            'Can you explain more deeply how this relates to quitting smoking '
                            'and give me personalized advice to improve it?';

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatbotPage(
                              userId: ref.read(userProvider).userId,
                              initialPrompt: prompt,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: metric["color"] as Color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Learn More',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void showWeeklyDetails(
  BuildContext context,
  Map<String, dynamic> metric,
  List<DailyValue> weeklyValues,
  Color cardColor,
  bool isDark,
) {
  final metricKey = metric["title"] as String;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppThemes.darkCardColor : cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppThemes.darkCardColor : cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metric["icon"] as IconData,
              size: 40,
              color: metric["color"] as Color,
            ),
            const SizedBox(height: 12),
            Text(
              metric["title"] as String,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppThemes.darkTextColor : AppThemes.lightSubtitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: ${metric["value"] as String}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: metric["color"] as Color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Last 7 Days",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: getMaxYForMetric(metricKey, weeklyValues),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: getIntervalForMetric(metricKey),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.1 * 255).round()),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  baselineY: 0,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      maxContentWidth: 250,
                      getTooltipColor: (group) => metric["color"] as Color,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = weeklyValues[groupIndex];
                        String formattedValue;

                        if (metricKey == "Steps") {
                          if (value.value >= 10000) {
                            formattedValue =
                                '${(value.value / 1000).toStringAsFixed(0)}k';
                          } else {
                            formattedValue =
                                '${(value.value / 1000).toStringAsFixed(1)}k';
                          }
                        } else if (metricKey == "Sleep") {
                          final hours = value.value.floor();
                          final minutes =
                              ((value.value - hours) * 60).round();
                          formattedValue = '${hours}h ${minutes}m';
                        } else if (metricKey == "Heart Rate") {
                          formattedValue = '${value.value.toInt()} bpm';
                        } else if (metricKey == "Blood Oxygen") {
                          formattedValue = '${value.value.toInt()}%';
                        } else if (metricKey == "Stress Level") {
                          formattedValue = '${value.value.toInt()}%';
                        } else if (metricKey == "Weight / BMI") {
                          final height = 1.75;
                          final bmi = value.value / (height * height);

                          String healthStatus;
                          if (bmi < 18.5) {
                            healthStatus = "Underweight";
                          } else if (bmi < 25) {
                            healthStatus = "Healthy";
                          } else if (bmi < 30) {
                            healthStatus = "Overweight";
                          } else if (bmi < 40) {
                            healthStatus = "Obese";
                          } else {
                            healthStatus = "Morbidly Obese";
                          }

                          formattedValue =
                              '${value.value.toStringAsFixed(1)} kg - BMI ${bmi.toStringAsFixed(1)}';

                          return BarTooltipItem(
                            '${value.day}: $formattedValue\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: healthStatus,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.black87
                                      : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        } else {
                          formattedValue = value.value.toInt().toString();
                        }

                        return BarTooltipItem(
                          '${value.day}: $formattedValue\n',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  getQualityForValue(metricKey, value.value),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.black87
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (response != null &&
                          response.spot != null &&
                          event is FlTapUpEvent) {
                        final index = response.spot!.touchedBarGroupIndex;
                        showDailyDetails(
                          context,
                          weeklyValues[index],
                          metric,
                          cardColor,
                          isDark,
                        );
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyValues.length) {
                            final dayAbbreviation =
                                weeklyValues[index].day.substring(0, 3);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dayAbbreviation,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (metricKey == "Steps") {
                            if (value % 2000 == 0 && value >= 2000) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  '${(value ~/ 1000)}k',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }
                          } else if (metricKey == "Weight / BMI") {
                            if (value % 5 == 0 &&
                                value >= 0 &&
                                value <= 80) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }
                          } else if (value %
                                  getIntervalForMetric(metricKey) ==
                              0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        interval: getIntervalForMetric(metricKey),
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyValues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.value.toDouble(),
                          color: metric["color"] as Color,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.check,
                color: isDark ? Colors.black87 : Colors.white,
              ),
              label: Text(
                "OK",
                style: TextStyle(
                  color: isDark ? Colors.black87 : Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: metric["color"] as Color,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}
