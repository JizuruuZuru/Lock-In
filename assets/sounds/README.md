# Audio Assets

Place these files in `assets/sounds/`.

## Correct Answer SFX

Use these 4 files for random correct answer sounds:

- `correct_1.mp3`
- `correct_2.mp3`
- `correct_3.mp3`
- `correct_4.mp3`

## Incorrect Splash SFX

Use these 4 files for random incorrect splash sounds:

- `incorrect_1.mp3`
- `incorrect_2.mp3`
- `incorrect_3.mp3`
- `incorrect_4.mp3`

## Level Up SFX

Played when `LevelUpPopup` appears:

- `levelup.wav`

## Page BGM (per page, randomized)

- Home Menu:
  - `bgm_home_1.mp3`
  - `bgm_home_2.mp3`
- Login:
  - `bgm_login_1.mp3`
  - `bgm_login_2.mp3`
- Register:
  - `bgm_register_1.mp3`
  - `bgm_register_2.mp3`
- Math Game:
  - `bgm_math_1.mp3`
  - `bgm_math_2.mp3`
- English Grammar (not supplied yet — currently falls back to the Home
  tracks in `sound_service.dart`; drop these two files in and switch
  `_bgmGroupKey[BgmPage.english]` back to `'bgm_english'` once added):
  - `bgm_english_1.mp3`
  - `bgm_english_2.mp3`
- Number Memory:
  - `bgm_memory_1.mp3`
  - `bgm_memory_2.mp3`

## How to get sound files:

1. **Freesound.org** - Free sound effects library
   - Search for "correct sound" or "success chime"

2. **Zapsplat.com** - Free sound effects
   - Search for "correct answer" or "success"

3. **Pixabay.com** - Free sounds and music
   - Search for "correct ding" or "success sound"

4. **Generate your own** using:
   - Online tone generators
   - Audacity (free audio editor)
   - FL Studio or other DAWs

## Format requirements:

- Format: MP3 (or WAV, OGG, etc. - supported by audioplayers)
- Duration: 0.5-1.5 seconds (short and snappy)
- Quality: 128-320 kbps
- Sample Rate: 44.1 kHz or 48 kHz

## Example sounds to use:

- Simple "ding" sound
- Bell chime
- Video game "level up" sound
- Upbeat notification tone

## Notes

- BGM transitions are faded in/out with easing.
- If a file is missing, playback safely falls back (no crash).
- Duplicate/repeated triggers are throttled to avoid stacked playback.
