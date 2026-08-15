// Static demonstration data for the biometrics dashboard. The screen labels
// these values as placeholders; until real wearable wiring is
// in, the same fake data lives here as a single source of truth.

class DailyValue {
  final String day;
  final double value;
  final String details;

  const DailyValue({
    required this.day,
    required this.value,
    required this.details,
  });
}

const Map<String, List<DailyValue>> weeklyData = {
  "Heart Rate": [
    DailyValue(day: "Monday", value: 75.0, details: "75 bpm — Steady heart rate"),
    DailyValue(day: "Tuesday", value: 78.0, details: "78 bpm — Normal and balanced"),
    DailyValue(day: "Wednesday", value: 72.0, details: "72 bpm — Healthy resting rate"),
    DailyValue(day: "Thursday", value: 74.0, details: "74 bpm — Within normal range"),
    DailyValue(day: "Friday", value: 80.0, details: "80 bpm — At the upper normal limit"),
    DailyValue(day: "Saturday", value: 70.0, details: "70 bpm — Ideal heart rate"),
    DailyValue(day: "Sunday", value: 68.0, details: "68 bpm — Slightly lower but still healthy"),
  ],
  "Blood Oxygen": [
    DailyValue(day: "Monday", value: 96.0, details: "96% — Good oxygen saturation"),
    DailyValue(day: "Tuesday", value: 97.0, details: "97% — Excellent oxygen level"),
    DailyValue(day: "Wednesday", value: 95.0, details: "95% — Steady and within normal range"),
    DailyValue(day: "Thursday", value: 98.0, details: "98% — Ideal oxygen level!"),
    DailyValue(day: "Friday", value: 94.0, details: "94% — Slightly lower but close to normal"),
    DailyValue(day: "Saturday", value: 99.0, details: "99% — Nearly perfect!"),
    DailyValue(day: "Sunday", value: 97.0, details: "97% — Healthy and stable breathing"),
  ],
  "Steps": [
    DailyValue(day: "Monday", value: 7500.0, details: "7.500 — Good effort, within range"),
    DailyValue(day: "Tuesday", value: 8200.0, details: "8.200 — Very good step count!"),
    DailyValue(day: "Wednesday", value: 10500.0, details: "10.500 — Excellent! Over 10k steps"),
    DailyValue(day: "Thursday", value: 6800.0, details: "6.800 — Steady, but room for improvement"),
    DailyValue(day: "Friday", value: 9200.0, details: "9.200 — Great walking today!"),
    DailyValue(day: "Saturday", value: 12000.0, details: "12.000 — Impressive activity!"),
    DailyValue(day: "Sunday", value: 8500.0, details: "8.500 — Satisfying step count"),
  ],
  "Sleep": [
    DailyValue(day: "Monday", value: 6.5, details: "6h 30m — Moderate rest"),
    DailyValue(day: "Tuesday", value: 7.2, details: "7h 12m — Good sleep quality"),
    DailyValue(day: "Wednesday", value: 8.0, details: "8h 00m — Excellent sleep"),
    DailyValue(day: "Thursday", value: 6.0, details: "6h 00m — Barely enough rest"),
    DailyValue(day: "Friday", value: 7.5, details: "7h 30m — Refreshing and satisfying"),
    DailyValue(day: "Saturday", value: 8.5, details: "8h 30m — Perfect sleep, well done!"),
    DailyValue(day: "Sunday", value: 7.0, details: "7h 00m — Steady and healthy sleep"),
  ],
  "Stress Level": [
    DailyValue(day: "Monday", value: 75.0, details: "75% — Moderate stress level"),
    DailyValue(day: "Tuesday", value: 50.0, details: "50% — Low stress, good balance"),
    DailyValue(day: "Wednesday", value: 100.0, details: "100% — Very high stress, be careful"),
    DailyValue(day: "Thursday", value: 75.0, details: "75% — Returning to moderate levels"),
    DailyValue(day: "Friday", value: 100.0, details: "100% — High stress, relaxation needed"),
    DailyValue(day: "Saturday", value: 25.0, details: "25% — Very relaxed day"),
    DailyValue(day: "Sunday", value: 50.0, details: "50% — Low stress, balanced"),
  ],
  "Weight / BMI": [
    DailyValue(day: "Monday", value: 72.5, details: "72.5 kg — BMI 23.7\nHealthy weight"),
    DailyValue(day: "Tuesday", value: 72.3, details: "72.3 kg — BMI 23.6\nGood balance"),
    DailyValue(day: "Wednesday", value: 72.0, details: "72.0 kg — BMI 23.5\nIdeal range"),
    DailyValue(day: "Thursday", value: 71.8, details: "71.8 kg — BMI 23.4\nSteadily healthy"),
    DailyValue(day: "Friday", value: 72.2, details: "72.2 kg — BMI 23.6\nNormal"),
    DailyValue(day: "Saturday", value: 72.4, details: "72.4 kg — BMI 23.7\nHealthy weight"),
    DailyValue(day: "Sunday", value: 72.1, details: "72.1 kg — BMI 23.5\nStable and healthy"),
  ],
};

const Map<String, String> metricContext = {
  "Heart Rate": "Heart rate indicates cardiovascular recovery.",
  "Blood Oxygen":
      "Blood oxygen levels show how efficiently your lungs and heart deliver oxygen after quitting smoking.",
  "Steps": "Steps represent daily physical activity and exercise.",
  "Sleep": "Sleep duration and quality affect recovery and cravings.",
  "Stress Level": "Stress management is key to staying smoke-free.",
  "Weight / BMI": "Weight and metabolism often change after quitting smoking.",
};
