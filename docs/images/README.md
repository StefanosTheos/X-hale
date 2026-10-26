# Application screenshots

The root README uses the updated application captures supplied in the project's local `Pics/` folder. They replace the earlier `assets/icons/` screenshots. The documentation images were prepared on 26 October 2026.

| Documentation image | Original local source | Final dimensions |
| --- | --- | --- |
| `progress-dashboard.webp` | `Pics/dashboard.jpg` | 1080 × 2104 |
| `hailey-conversation.webp` | `Pics/chatbot_interaction.jpg` | 1080 × 2104 |
| `guided-breathing.webp` | `Pics/breathing_technique.jpg` | 1080 × 2104 |
| `milestones.webp` | `Pics/milestones.jpg` | 1080 × 2104 |
| `challenges.webp` | `Pics/challenge_crop_1.jpg` | 1080 × 722 |
| `health-benefit.webp` | `Pics/health_benefits_cropped_2.jpg` | 1080 × 727 |

## Cropping and image fidelity

For the four full-device captures, the source dimensions are 1080 × 2340. The retained rectangle is `(left=0, top=96, right=1080, bottom=2200)`, using an exclusive right/bottom boundary. This removes the clock/battery/notification bar and Android's three-button system navigation bar. App headers, app navigation, chat actions, input controls and breathing controls remain intact.

The challenge and health-benefit sources were already tightly framed by the owner and contain neither system bar; their full supplied image areas are retained. No composite or simulated interface was used.

All six images use **lossless WebP** at their retained native resolution, without rescaling, text replacement, retouching or generated content. The decoded output pixels were checked against the corresponding decoded source crop and match exactly. The gallery totals approximately 1.4 MB. The three lead images have matching dimensions and display at 240 pixels wide; the two detail cards display at 360 pixels wide. Clicking an image opens its full-resolution file.

## Provenance and interpretation

The source files have no recorded EXIF capture date or exact code revision. The dashboard and conversation show September 2026 dates, but those visible application timestamps do not establish the precise capture date or deployed model/corpus revision. The preparation date above is not a claim that the app was recaptured on that day.

The Hailey capture shows a supplied interaction about cravings and app-action links. Displayed progress, savings and health-benefit information illustrate the interface; screenshots are not benchmark results or evidence of clinical effectiveness. The health-benefit timeline is informational, not an individual physiological measurement. Other asset-rights work remains in [third-party notices](../../THIRD_PARTY_NOTICES.md).

The local source folder is kept out of routine commits; only these curated, cropped documentation images are published. Source files remain unchanged.

For future captures, exclude personal information, real messages/diary entries, credentials and notification contents; record capture date and code revision. Any biometrics image must label its readings as demonstration data.
