import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/home_pages/biometrics_data.dart';
import 'package:smoking/pages/home_pages/biometrics_dialogs.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/user_provider.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class BiometricsPage extends ConsumerStatefulWidget {
  const BiometricsPage({super.key});

  @override
  ConsumerState<BiometricsPage> createState() => _BiometricsPageState();
}

class _BiometricsPageState extends ConsumerState<BiometricsPage> {
  bool _isLoading = false;
  bool _isVerifyingCredentials = false;
  bool _isFetchingData = false;
  bool _isShowingDialog = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    _checkSamsungHealthStatus();
    super.initState();
  }

  void _checkSamsungHealthStatus() async {
    final user = ref.read(userProvider);
    if (!user.hasSamsungHealth) {
      setState(() => _isShowingDialog = true);
      await Future.delayed(const Duration(milliseconds: 500));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSamsungHealthDialog(
          ref.isDark,
        ).then((_) {
          if (mounted) {
            setState(() => _isShowingDialog = false);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _isShowingDialog = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    if (_isShowingDialog) {
      return Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppThemes.darkMotivationGradient
                  : AppThemes.lightGradient,
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.blueAccent : Colors.blue,
            ),
          ),
        ),
      );
    }
    final metrics = [
      {
        "title": "Heart Rate",
        "value": "72 bpm",
        "icon": Icons.favorite,
        "color": Colors.redAccent,
        "tip": "Resting heart rate has improved after quitting smoking.",
        "currentValue": 72.0,
        "minValue": 60.0,
        "maxValue": 85.0,
      },
      {
        "title": "Blood Oxygen",
        "value": "97%",
        "icon": Icons.bloodtype,
        "color": const Color.fromARGB(255, 90, 188, 215),
        "tip": "Good oxygen levels improve recovery after quitting.",
        "currentValue": 97.0,
        "minValue": 0.0,
        "maxValue": 100.0,
      },
      {
        "title": "Steps",
        "value": "8.200 steps",
        "icon": Icons.directions_walk,
        "color": Colors.green,
        "tip": "Exercise helps reduce cravings for cigarettes.",
        "currentValue": 8200.0,
        "minValue": 5000.0,
        "maxValue": 12000.0,
      },
      {
        "title": "Sleep",
        "value": "7h 20m",
        "icon": Icons.nightlight_round,
        "color": Colors.blue,
        "tip": "Sleep quality significantly improves after quitting.",
        "currentValue": 7.3,
        "minValue": 5.5,
        "maxValue": 9.5,
      },
      {
        "title": "Stress Level",
        "value": "50%",
        "icon": Icons.self_improvement,
        "color": Colors.orange,
        "tip": "Calmness reduces the risk of relapse.",
        "currentValue": 50.0,
        "minValue": 0.0,
        "maxValue": 100.0,
      },
      {
        "title": "Weight / BMI",
        "value": "72kg / 23.1",
        "icon": Icons.fitness_center,
        "color": Colors.teal,
        "tip": "Balanced diet controls potential weight gain.",
        "currentValue": 72.0,
        "minValue": 70.0,
        "maxValue": 74.0,
      },
    ];
    final List<Color> cardColors = const [
      Color.fromARGB(255, 255, 230, 230),
      Color.fromARGB(255, 226, 252, 255),
      Color(0xFFE8F5E9),
      Color.fromARGB(255, 226, 238, 255),
      Color.fromARGB(255, 255, 238, 223),
      Color.fromARGB(255, 229, 255, 253),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vitals & Activity',
          style: TextStyle(
            color: isDark ? Colors.white : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : AppThemes.lightIconColor,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : AppThemes.lightIconColor,
            ),
            onPressed:
                _isLoading
                    ? null
                    : () {
                      setState(() {
                        _isLoading = true;
                      });

                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() {
                          _isLoading = false;
                        });
                      });
                    },
          ),
        ],
      ),
      body:
          _isLoading
              ? Container(
                decoration: BoxDecoration(
                  gradient:
                      isDark
                          ? AppThemes.darkExploreGradient
                          : AppThemes.lightGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.black.withAlpha((0.3 * 255).round())
                                  : Colors.white.withAlpha((0.7 * 255).round()),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.2 * 255).round(),
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.blueAccent : Colors.blue,
                            ),
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      AnimatedOpacity(
                        opacity: _isLoading ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 500),
                        child: Text(
                          "Fetching latest Samsung Health data..",
                          style: TextStyle(
                            color: isDark ? AppThemes.darkTextColor : AppThemes.lightSubtitleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              )
              : SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient:
                        isDark
                            ? AppThemes.darkExploreGradient
                            : AppThemes.lightGradient,
                  ),
                  child: GridView.builder(
                    itemCount: metrics.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemBuilder: (context, index) {
                      final metric = metrics[index];
                      final color = cardColors[index % cardColors.length];
                      final metricKey = metric["title"] as String;
                      final minValue = metric["minValue"] as double;
                      final maxValue = metric["maxValue"] as double;
                      final yRange = maxValue - minValue;
                      final padding = yRange * 0.1;

                      final weeklyValues = weeklyData[metricKey]!;
                      final spots =
                          weeklyValues.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.value.toDouble(),
                            );
                          }).toList();

                      return GestureDetector(
                        onTap:
                            () => showWeeklyDetails(
                              context,
                              metric,
                              weeklyValues,
                              color,
                              isDark,
                            ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? color.withAlpha((0.9 * 255).round())
                                    : color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  ((isDark ? 0.2 : 0.1) * 255).round(),
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isDark)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: AppThemes.darkCardOverlay,
                                      ),
                                    ),
                                  Icon(
                                    metric["icon"] as IconData,
                                    size: 32,
                                    color: metric["color"] as Color,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    metric["title"] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? Colors.black87
                                              : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    metric["value"] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.black87
                                              : metric["color"] as Color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 30,
                                    child: LineChart(
                                      LineChartData(
                                        minY: minValue - padding,
                                        maxY: maxValue + padding,
                                        titlesData: const FlTitlesData(
                                          show: false,
                                        ),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        lineTouchData: LineTouchData(
                                          enabled: true,
                                          touchTooltipData: LineTouchTooltipData(
                                            fitInsideHorizontally: true,
                                            maxContentWidth: 250,
                                            getTooltipColor:
                                                (spot) =>
                                                    metric["color"] as Color,
                                            getTooltipItems: (spots) {
                                              final spot = spots.first;
                                              final index = spot.x.toInt();
                                              final value = weeklyValues[index];

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
                                                final hours =
                                                    value.value.floor();
                                                final minutes =
                                                    ((value.value - hours) * 60)
                                                        .round();
                                                formattedValue =
                                                    '${hours}h ${minutes}m';
                                              } else if (metricKey ==
                                                  "Heart Rate") {
                                                formattedValue =
                                                    '${value.value.toInt()} bpm';
                                              } else if (metricKey ==
                                                  "Blood Oxygen") {
                                                formattedValue =
                                                    '${value.value.toInt()}%';
                                              } else if (metricKey ==
                                                  "Stress Level") {
                                                formattedValue =
                                                    '${value.value.toInt()}%';
                                              } else if (metricKey ==
                                                  "Weight / BMI") {
                                                final height = 1.75;
                                                final bmi =
                                                    value.value /
                                                    (height * height);

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
                                                  healthStatus =
                                                      "Morbidly Obese";
                                                }

                                                formattedValue =
                                                    '${value.value.toStringAsFixed(1)} kg - BMI ${bmi.toStringAsFixed(1)}';

                                                return [
                                                  LineTooltipItem(
                                                    '${value.day}: $formattedValue\n',
                                                    TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: healthStatus,
                                                        style: TextStyle(
                                                          color:
                                                              isDark
                                                                  ? Colors
                                                                      .black87
                                                                  : Colors
                                                                      .white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ];
                                              } else {
                                                formattedValue =
                                                    value.value
                                                        .toInt()
                                                        .toString();
                                              }

                                              return [
                                                LineTooltipItem(
                                                  '${value.day}: $formattedValue\n',
                                                  TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: getQualityForValue(
                                                        metricKey,
                                                        value.value,
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ];
                                            },
                                          ),
                                          touchCallback: (event, response) {
                                            if (response != null &&
                                                response.lineBarSpots != null &&
                                                response
                                                    .lineBarSpots!
                                                    .isNotEmpty &&
                                                event is FlTapUpEvent) {
                                              final index =
                                                  response.lineBarSpots!.first.x
                                                      .toInt();
                                              showDailyDetails(
                                                context,
                                                weeklyValues[index],
                                                metric,
                                                color,
                                                isDark,
                                              );
                                            }
                                          },
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: spots,
                                            isCurved: true,
                                            color: metric["color"] as Color,
                                            dotData: const FlDotData(
                                              show: false,
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: (metric["color"] as Color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tap for details',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isDark
                                              ? Colors.black54
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap:
                                      () => showInfoDialog(
                                        context,
                                        ref,
                                        metric,
                                        color,
                                        isDark,
                                      ),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
    );
  }

  Future<void> _showSamsungHealthDialog(bool isDark) async {
    final formKey = GlobalKey<FormState>();
    String? emailError;
    String? passwordError;
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SamsungHealthDialog',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim1, anim2) {
        return Container(
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkMotivationGradient
                    : AppThemes.lightGradient,
          ),
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient:
                          isDark
                              ? AppThemes.darkDialogGradient
                              : AppThemes.lightDialogGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/Samsung_Health_2025_logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Do you have a Samsung Health account?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sync it now to track your\nhealth metrics',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor.withAlpha(
                                          (0.7 * 255).round(),
                                        )
                                        : AppThemes.lightTextColor.withAlpha(
                                          (0.7 * 255).round(),
                                        ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            if (!_isVerifyingCredentials &&
                                !_isFetchingData) ...[
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  errorText: emailError,
                                  labelStyle: TextStyle(
                                    color:
                                        isDark
                                            ? AppThemes.darkTextColor.withAlpha(
                                              (0.7 * 255).round(),
                                            )
                                            : AppThemes.lightTextColor
                                                .withAlpha((0.7 * 255).round()),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          isDark
                                              ? AppThemes.activeColor
                                              : AppThemes.lightAppBarColor,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color:
                                        isDark
                                            ? AppThemes.darkTextColor.withAlpha(
                                              (0.7 * 255).round(),
                                            )
                                            : AppThemes.lightTextColor
                                                .withAlpha((0.7 * 255).round()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorText: passwordError,
                                  labelStyle: TextStyle(
                                    color:
                                        isDark
                                            ? AppThemes.darkTextColor.withAlpha(
                                              (0.7 * 255).round(),
                                            )
                                            : AppThemes.lightTextColor
                                                .withAlpha((0.7 * 255).round()),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          isDark
                                              ? AppThemes.activeColor
                                              : AppThemes.lightAppBarColor,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color:
                                        isDark
                                            ? AppThemes.darkTextColor.withAlpha(
                                              (0.7 * 255).round(),
                                            )
                                            : AppThemes.lightTextColor
                                                .withAlpha((0.7 * 255).round()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ] else if (_isVerifyingCredentials) ...[
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? Colors.blue[200]!
                                            : Colors.blue[700]!,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Verifying Samsung Health credentials..',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ] else if (_isFetchingData) ...[
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? Colors.blue[200]!
                                            : Colors.blue[700]!,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Fetching latest Samsung Health data..',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            if (!_isVerifyingCredentials && !_isFetchingData)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx, false);
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isDark
                                              ? AppThemes.darkCardColor
                                              : Colors.grey[300]!,
                                      foregroundColor:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        emailError =
                                            _emailController.text.isEmpty
                                                ? 'E-mail is required'
                                                : null;
                                        passwordError =
                                            _passwordController.text.isEmpty
                                                ? 'Password is required'
                                                : null;
                                      });

                                      if (emailError != null ||
                                          passwordError != null) {
                                        return;
                                      }

                                      setState(
                                        () => _isVerifyingCredentials = true,
                                      );
                                      await Future.delayed(
                                        const Duration(seconds: 3),
                                      );

                                      setState(() {
                                        _isVerifyingCredentials = false;
                                        _isFetchingData = true;
                                      });
                                      await Future.delayed(
                                        const Duration(seconds: 3),
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(ctx, true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isDark
                                              ? AppThemes.darkCloseButtonColor
                                              : AppThemes.lightCloseButtonColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Sync Now'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isShowingDialog = false);
    }

    if (result == true) {
      await _verifySamsungHealthCredentials();
    }
  }

  Future<void> _verifySamsungHealthCredentials() async {
    try {
      await ref.read(userProvider.notifier).updateSamsungHealthStatus(true);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Samsung Health connected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting Samsung Health: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
