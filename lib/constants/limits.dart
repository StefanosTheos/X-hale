// App-wide numeric limits hoisted here so the same value isn't typed (and
// later edited inconsistently) at multiple call sites. Add new constants as
// the same magic number shows up in two or more places.

/// Hard cap on the length of a single diary entry (validated in
/// [DiaryPage._addEntry] and enforced by the input field's `maxLength`).
const int kDiaryMaxChars = 200;

/// Hard cap on the length of a single motivation card (matches the diary
/// limit; motivations show on small cards so a longer string would overflow
/// the layout anyway).
const int kMotivationMaxChars = 120;

/// Total achievement-points budget. The progress bar on the achievements
/// page renders the user's current total as a fraction of this value.
const int kMaxAchievementPoints = 19800;
