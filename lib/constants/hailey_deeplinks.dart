enum HaileyDeeplinkTarget {
  breathing,
  spin,
  games,
  diary,
  stretches,
  dashboard,
  achievements,
  sounds,
}

const Map<String, HaileyDeeplinkTarget> haileyDeeplinkRegistry = {
  'xhale://breathing': HaileyDeeplinkTarget.breathing,
  'xhale://distractions/spin': HaileyDeeplinkTarget.spin,
  'xhale://explore/games': HaileyDeeplinkTarget.games,
  'xhale://diary/new': HaileyDeeplinkTarget.diary,
  'xhale://distractions/stretches': HaileyDeeplinkTarget.stretches,
  'xhale://dashboard': HaileyDeeplinkTarget.dashboard,
  'xhale://achievements': HaileyDeeplinkTarget.achievements,
  'xhale://distractions/sounds': HaileyDeeplinkTarget.sounds,
};

HaileyDeeplinkTarget? resolveHaileyDeeplink(String uri) =>
    haileyDeeplinkRegistry[uri];
