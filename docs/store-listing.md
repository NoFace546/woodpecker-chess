# Play Store listing — Woodpecker Chess

## App name
**Woodpecker Chess**
(under 30 chars; "Woodpecker" alone may collide with other apps — adding "Chess" disambiguates)

## Short description (max 80 chars)
**Tactical puzzle training using the Woodpecker Method. Drill, repeat, improve.**
(78 chars)

Alternative:
- "Train chess tactics by drilling the same puzzle set across rounds." (66 chars)
- "Chess puzzle trainer based on the Woodpecker Method by Smith & Tikkanen." (72 chars)

## Full description (max 4000 chars)

```
Woodpecker Chess is a focused tactics trainer built around the Woodpecker
Method — solving the same set of tactical puzzles in repeated rounds to build
fast, automatic pattern recognition.

The method, popularised by GMs Axel Smith and Hans Tikkanen, is simple:
pick a set of puzzles at your level, solve them, then solve the SAME set
again. And again. Each round you go faster while keeping accuracy high.
After 5–7 rounds, the patterns become reflexive.

— FEATURES —

• Adaptive Elo rating
  Every puzzle has a Lichess rating; your Elo adjusts per puzzle.
  Aggressive K-factor early so your level converges in ~10 attempts.

• Recommended training, built for you
  Tap one button and get a ~150-puzzle set tailored to your weaknesses
  and current Elo (comfort zone: -200 / +100). Designed to be drilled
  Woodpecker-style across multiple rounds.

• Per-set progression tracking
  Round-by-round accuracy, median solve time, time savings vs round 1,
  flow streaks (longest chain of fast solves). When you hit 90%+ accuracy
  AND 35% faster than round 1, the app suggests archiving — the set is
  mastered, time to build the next.

• Strengths & weaknesses by theme
  Per-tactic breakdown: forks, pins, mate-in-N, and more. Ranked by Wilson
  lower bound so a 90% on 20 puzzles ranks above a 100% on 3. Trend arrows
  show improving / declining themes.

• Random puzzles
  Free-play mode tuned to your current Elo. Counts toward your stats.

• Play vs Stockfish
  7 difficulty levels from Newcomer (~800 Elo) to Expert (~2400 Elo).
  Resume any game in progress.

• Backup & restore
  Export your full progress to a file you control. Restore on a new device.

— PRIVACY —

100% local. No accounts, no analytics, no servers, no ads. Your puzzles,
attempts, Elo, and bot games never leave your device unless you choose
to share a backup file. The Stockfish chess engine runs on-device.

— ATTRIBUTION —

Puzzles by Lichess (CC0). Engine: Stockfish. UI libraries: chessground
and dartchess (Lichess, GPL-3.0). The app is GPL-3.0.

— REQUIREMENTS —

Requires Android 5.0+ (API 21+). ~110 MB after install.
```

## Category
**Education** (primary) → "Brain & puzzle training" / "Reference"
Or **Games → Board** if Play Store wants a game category.

Education is the better fit — this isn't a game you play to win, it's a
training tool. (Lichess uses "Board" but that's because it's a play-against-others app.)

## Content rating
- Violence: None
- Sexual content: None
- Profanity: None
- Drugs/alcohol: None
- Gambling: None
- User-generated content: None
- Location: None
- Personal info: None

→ **Everyone** rating.

## Data safety questionnaire (Play Console)
- Does your app collect or share user data? **No**
- (No further questions if "No")

## Tags / keywords for store search
- chess
- chess puzzles
- chess tactics
- woodpecker method
- tactics trainer
- chess training
- chess improvement

## Screenshot suggestions (5–8 recommended)

For best store impression, capture in this order:

1. **Home screen** with at least 2–3 sets in "My sets"
   — shows: Find your rating card (if applicable), Recommended training,
   menu cards, sets list. Sets the visual context.

2. **Active session** — board mid-puzzle with HUD
   — shows: chessboard, hint shapes, status bar with "Find the best move",
   move counter. The core gameplay screen.

3. **Round summary dialog** — ideally with mastery banner triggered
   — shows: round stats, comparison vs prior round, hardest puzzles,
   confetti residue, "Archive set" CTA. Demonstrates the Woodpecker payoff.

4. **Strengths & weaknesses** screen
   — shows: phase radar, top-3 weaknesses with red cards, top-3 strengths
   with green cards. Demonstrates analytics depth.

5. **Per-set progression** — round-by-round chart
   — shows: accuracy trend, median time trend across multiple rounds.
   The Woodpecker speedup story visualised.

6. **Recommended training explainer dialog** (info icon)
   — shows: how the algorithm picks puzzles. Low priority but shows
   transparency.

7. **Bot game in progress** — shows: chessboard with Stockfish playing.
   Optional, only if it strengthens the listing.

8. **About screen** — credits + privacy statement.
   Optional, signals trust.

### Screenshot specs
- Phone: at least 2 phone screenshots, recommended 3–8.
- Min resolution: 320 px on shortest side.
- Max resolution: 3840 px on longest side.
- 16:9, 9:16, or close. PNG or JPEG.
- No frames around screenshots — Play Store frames them.

### How to capture
On Pixel 7a:
1. Open app, navigate to target screen.
2. Power + Volume Down for screenshot.
3. Pull from /Pictures/Screenshots/ via Files app or USB.
4. Crop status bar if you want clean shots (Play Store accepts either way).

## Feature graphic (optional but recommended)
1024 × 500 PNG. Used at top of store listing. Could be a stylized board
+ "Drill. Repeat. Improve." text. Skip for first internal-testing release;
add before public launch.

## Internal testing setup steps

1. Play Console → Create app
   - App name: Woodpecker Chess
   - Default language: English (US)
   - Type: App
   - Free / Paid: Free
   - Declarations: confirm Play policies

2. Privacy policy URL → host docs/privacy.md somewhere public:
   - Easy: GitHub repo → enable Pages on /docs branch → URL becomes
     https://<username>.github.io/<repo>/privacy
   - Easier: paste contents into a public Gist; use the Raw URL.

3. App content
   - Privacy policy URL: as above
   - App access: All functionality available without restrictions
   - Ads: No
   - Content rating: complete questionnaire → Everyone
   - Target audience: 13+ (chess can be marketed broadly; choosing 13+
     avoids COPPA paperwork for under-13)
   - Data safety: declare no data collection (truthful)
   - Government apps / health apps: No to all

4. Main store listing
   - Use copy from sections above
   - Upload icon (auto-extracted from .aab) and screenshots (3+ minimum)

5. Production → ❌ skip; we want Internal testing only

6. Testing → Internal testing → Create new release
   - Upload app-release.aab
   - Release notes: "First internal beta. Please report bugs via
     Settings → Report a bug."
   - Save → Review release → Start rollout

7. Internal testing → Testers tab
   - Create email list, add tester emails
   - Copy "opt-in URL" — share with testers

8. Tester flow
   - Tester clicks opt-in URL → accepts → Play Store opens app page
   - Install — first time may take a few minutes for Play to bake the APK

## Versjons-bumping for fremtidige releases

Hver gang du vil pushe en ny versjon må `pubspec.yaml`s `version: 0.1.0+1`-felt
inkrementere. Spesielt `+N` (build number) MÅ være høyere enn forrige opplastning,
ellers avviser Play Console .aab-en. Eks: 0.1.0+1 → 0.1.0+2 → 0.1.1+3.
