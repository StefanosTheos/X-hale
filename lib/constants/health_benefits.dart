class HealthBenefits {
  static const List<Map<String, dynamic>> allBenefits = [
    // Low impact
    {
      "id": "benefit_20min",
      "title": "Heart Rate & Blood Pressure Drop",
      "description":
          "Your heart rate and blood pressure return to normal levels.",
      "time_interval": 20,
      "time_unit": "minutes",
      "severity": "low",
      "icon": "assets/icons/blood-pressure.png",
    },
    {
      "id": "benefit_12hours",
      "title": "Carbon Monoxide Normalizes",
      "description": "Carbon monoxide levels in your blood drop to normal.",
      "time_interval": 720, // 12 hours
      "time_unit": "minutes",
      "severity": "low",
      "icon": "assets/icons/carbon-monoxide.png",
    },
    {
      "id": "benefit_24hours",
      "title": "Nicotine Levels Drop",
      "description": "Nicotine levels in your blood drop to zero.",
      "time_interval": 1440, // 24 hours
      "time_unit": "minutes",
      "severity": "low",
      "icon": "assets/icons/nicotine-down.png",
    },
    {
      "id": "benefit_48hours",
      "title": "Senses Improve",
      "description": "Your senses of taste and smell begin to improve.",
      "time_interval": 2880, // 48 hours
      "time_unit": "minutes",
      "severity": "low",
      "icon": "assets/icons/senses.png",
    },

    {
      "id": "benefit_2weeks",
      "title": "Circulation & Lung Function Improve",
      "description":
          "Your circulation improves, and lung function increases, making breathing easier.",
      "time_interval": 20160, // 2 weeks
      "time_unit": "minutes",
      "severity": "low",
      "icon": "assets/icons/circulation.png",
    },

    // Medium impact
    {
      "id": "benefit_1month",
      "title": "Increased Energy & Easier Breathing",
      "description":
          "You notice more energy and improved breathing with less coughing.",
      "time_interval": 43200, // 1 month
      "time_unit": "minutes",
      "severity": "medium",
      "icon": "assets/icons/energy-level.png",
    },
    {
      "id": "benefit_1to9months",
      "title": "Coughing & Shortness of Breath Decrease",
      "description":
          "You experience less coughing and reduced shortness of breath.",
      "time_interval": 219145, // 5 months
      "time_unit": "minutes",
      "severity": "medium",
      "icon": "assets/icons/cough.png",
    },
    {
      "id": "benefit_1year",
      "title": "Heart Disease Risk Halves",
      "description":
          "Your risk of coronary heart disease drops to about half that of a smoker.",
      "time_interval": 525600, // 1 year
      "time_unit": "minutes",
      "severity": "medium",
      "icon": "assets/icons/heart.png",
    },
    {
      "id": "benefit_1to2years",
      "title": "Heart Attack Risk Falls",
      "description":
          "Your risk of heart attack drops dramatically, nearing that of a non-smoker.",
      "time_interval": 1051200, // 2 years
      "time_unit": "minutes",
      "severity": "medium",
      "icon": "assets/icons/heart-attack.png",
    },
    //High Impact
    {
      "id": "benefit_3to6years",
      "title": "Coronary Heart Disease Risk Drops",
      "description":
          "Your risk of coronary heart disease decreases by about 50%.",
      "time_interval": 2629746, // ~5 years (3 to 6 years range)
      "time_unit": "minutes",
      "severity": "high",
      "icon": "assets/icons/coronary.png",
    },
    {
      "id": "benefit_5to10years",
      "title": "Cancer & Stroke Risk Lower",
      "description":
          "Risk of cancers of the mouth, throat, and voice box drops by half, stroke risk also decreases.",
      "time_interval": 4207593, // ~8 years (5 to 10 years)
      "time_unit": "minutes",
      "severity": "high",
      "icon": "assets/icons/stroke.png",
    },

    {
      "id": "benefit_10years",
      "title": "Lung Cancer Risk Halves",
      "description":
          "Your risk of lung cancer is about half that of a smoker, risks of bladder, esophagus, and kidney cancers decrease.",
      "time_interval": 5256000, // 10 years
      "time_unit": "minutes",
      "severity": "high",
      "icon": "assets/icons/cancer.png",
    },
    {
      "id": "benefit_15years",
      "title": "Heart Disease Risk Normalizes",
      "description":
          "Your risk of coronary heart disease approaches that of a non-smoker.",
      "time_interval": 7884000, // 15 years
      "time_unit": "minutes",
      "severity": "high",
      "icon": "assets/icons/heart-disease.png",
    },
    {
      "id": "benefit_20years",
      "title": "Cancer Risks Normalize",
      "description":
          "Your risk of various cancers (mouth, throat, voice box, pancreas, cervix) drops to that of a non-smoker.",
      "time_interval": 10512000, // 20 years
      "time_unit": "minutes",
      "severity": "high",
      "icon": "assets/icons/mortality.png",
    },
  ];

  static Map<String, dynamic>? getById(String id) {
    try {
      return allBenefits.firstWhere((benefit) => benefit['id'] == id);
    } catch (e) {
      return null;
    }
  }

}
