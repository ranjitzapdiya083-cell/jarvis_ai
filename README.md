# JARVIS AI — Flutter Voice Assistant

Your Voice. Your Phone. Your Assistant.

This is a real, buildable Flutter project matching the design screens
provided, with genuine Android functionality behind every button — not
mockups. It was generated in an environment without the Flutter SDK, so it
has **not** been built/run here. Follow the steps below on your own machine.

---

## 1. Requirements

- **Flutter SDK 3.27 or newer (stable channel)** — this project uses
  `CardThemeData` and `DropdownButtonFormField.initialValue`, both of
  which are newer Flutter APIs. An older Flutter version (e.g. 3.24) will
  fail to compile with errors like `The named parameter 'initialValue' isn't
  defined` or `The argument type 'CardThemeData' can't be assigned...`.
  Run `flutter --version` and `flutter upgrade` if you're on an older version.
- Android Studio (for SDK + emulator) or a physical Android device (Android 7.0 / API 24+)
- A Google Gemini API key (optional — only needed for free-form AI chat)

## 2. Setup

```bash
cd jarvis_ai
flutter pub get

# Android SDK path config
cp android/local.properties.template android/local.properties
# then edit android/local.properties and set sdk.dir / flutter.sdk to YOUR paths
```

## 3. Run

```bash
flutter devices          # confirm a device/emulator is attached
flutter run
```

## 4. Build a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

> The release build uses the **debug** signing config by default so it
> builds out of the box. Before publishing anywhere, generate a real
> keystore and update `android/app/build.gradle` → `signingConfigs.release`.

## 5. Build APK automatically via GitHub (no local setup needed)

This repo includes a ready-made GitHub Actions workflow at
`.github/workflows/build-apk.yml`. Once you push this project to a GitHub
repo, it builds the APK **for you on GitHub's own servers** — you don't
need Flutter/Android Studio installed locally at all.

**Steps:**
1. Create a new repo on GitHub and push this project:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
2. Go to your repo → **Actions** tab. The "Build APK" workflow runs
   automatically on every push.
3. Once it finishes (green check ✅), open that workflow run → scroll to
   **Artifacts** → download `jarvis-ai-release-apk` (or `-debug-apk`).
   It's a zip containing `app-release.apk` — install that on your phone.

**To create a proper GitHub Release with the APK attached** (instead of
just a build artifact), push a version tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```
This triggers the same workflow, and additionally publishes a GitHub
Release with `app-release.apk` attached for anyone to download.

**Bonus: automatic screenshot + crash logs on every build.** After the
APK builds, a second job (`emulator-check`) automatically boots a virtual
Android phone, installs the app, and captures:
- `jarvis-ai-emulator-screenshot` — a real screenshot of the Home screen
- `jarvis-ai-emulator-logcat` — the full system log from that run

This means you (or I) can verify the app actually renders correctly, or
see the exact crash reason, **without needing your own physical phone or
running anything locally**. If the app crashes on launch, this job fails
with a red ❌ instead of silently passing — so a broken build is obvious
from the Actions tab alone. Open the failed/passed run → **Artifacts** →
download the screenshot or logcat file.

> Note: the emulator job runs on GitHub's macOS runners (needed for
> hardware-accelerated emulation) and adds a few minutes to each workflow
> run — this is normal.

> Note: the workflow builds using the **debug signing config** (same as
> local builds) so it works out of the box. For a Play Store submission,
> add your own release keystore as GitHub Secrets and update
> `android/app/build.gradle` + the workflow accordingly.

## 7. Add your AI key (optional)

Open the app → Settings → AI & Conversation → choose "Google Gemini" →
paste your API key. It's stored locally on-device via SharedPreferences —
never bundled in source or sent anywhere except directly to Google's API.

---

## Your examples, explained honestly

| You say | What actually happens |
|---|---|
| "YouTube kholo" | ✅ Opens the YouTube app directly. |
| "WhatsApp pe king ko hy message karo" | ✅ Finds "king" in your contacts, opens WhatsApp with the chat + "hy" already typed in the box. **You still tap Send yourself** — WhatsApp/Android don't allow any third-party app to send a message on a personal account silently. This is a platform anti-spam rule, not something JARVIS can bypass (the only way around it is WhatsApp's separate, paid Business API with a verified business account). |
| "Screen lock karo" | ✅ Locks the screen — but only after you manually enable JARVIS's Accessibility Service once, in Settings → Accessibility. Android requires this explicit opt-in for any app that can lock the screen; there's no way to skip that step. |
| "Hey JARVIS bolu tab screen on hoga?" | ✅ Yes — saying the wake word now turns the screen on (see `WakeScreenReceiver.kt`), **as long as the JARVIS background service is still alive**. Caveat: some phone brands (Xiaomi/MIUI, Oppo, Vivo, etc.) kill background microphone access after a while unless you whitelist JARVIS in that phone's battery/autostart settings — that's a manufacturer restriction on all background apps, not a bug in this code. |

## What's genuinely implemented

| Area | Status |
|---|---|
| UI (Home orb, Chat, Commands, Settings, Background Assistant, Custom Commands, Permissions) | ✅ Matches provided design |
| Local Hinglish intent recognition (no network) | ✅ Real regex/keyword engine (`intent_engine.dart`) |
| Torch, battery, volume, brightness | ✅ Real plugin calls, honest failure messages |
| Open app / call / SMS / web & YouTube search / maps | ✅ Real Android intents |
| Speech-to-text / text-to-speech | ✅ `speech_to_text` + `flutter_tts` |
| Custom commands (create/edit/delete, multi-action) | ✅ Real SQLite persistence |
| Command history | ✅ Real SQLite persistence |
| Permissions screen | ✅ Live status from `permission_handler` |
| AI conversation | ✅ Real Gemini HTTP call — **requires your own API key** |
| Screen-off voice command | ⚠️ Wired to a real Android Accessibility Service, but **the user must manually enable it** in Settings → Accessibility (Android does not allow apps to bypass this — this is an OS-level security rule, not a limitation we can code around) |
| Background "Hey JARVIS" wake-word | ✅ Real continuous-listening restart-loop (`WakeWordServiceImpl`) running inside a genuine Android foreground service (`flutter_foreground_task`) with a persistent notification. **Honest caveat:** this is not a dedicated low-power DSP hotword engine like Picovoice Porcupine — it repeatedly restarts the on-device speech recognizer, so it uses more battery and has a brief (~0.5–1s) gap between listening sessions. Swap `WakeWordServiceImpl` for a Porcupine-backed implementation later if you want true low-power always-on detection; no other code needs to change. |
| Contact-name resolution for calls/SMS ("mummy ko call karo") | ✅ Real device contact lookup via `flutter_contacts`, with Contacts permission requested on first use |
| Persistent conversational memory | ✅ Every conversation (small talk + AI chat) is saved to SQLite (`chat_messages` table) and reloaded on every app start — JARVIS has real continuity across sessions, not just within one open app instance. Both the Home mic flow and the Chat screen share the same memory. |
| Greetings & small talk ("good morning", "kaise ho", "thank you") | ✅ Answered instantly with a warm, locally-generated reply — works even with zero AI configured, since these don't need real intelligence to answer naturally |
| Context-aware AI replies | ✅ When Gemini is configured, JARVIS's system prompt includes your last 5 real commands, so its answers can reference what you've actually been doing, not just the current message in isolation |
| Automated instrumentation/UI tests, CI pipeline, Play Store listing assets | ❌ Not included — out of scope for a single build session |

## Project structure

```
lib/
  core/            theme, DI (service locator), shared utils
  features/
    home/          orb UI + AssistantController (the main run loop)
    commands/      IntentEngine + CommandExecutor (text -> real action)
    device/        torch/battery/volume/brightness/app-launch services
    voice/         STT + TTS wrappers
    ai/            pluggable AiProvider (Gemini + local fallback)
    background/    real foreground service + continuous wake-word loop
    contacts/      real device contact lookup for name-based call/SMS
    custom_commands/  user-defined multi-action commands (SQLite)
    history/       command history (SQLite)
    settings/      all settings screens
    permissions/   permission_handler wrapper + screen
  services/database/  sqflite bootstrap
android/
  app/src/main/kotlin/com/jarvis/ai/
    MainActivity.kt              screen-off platform channel
    JarvisAccessibilityService.kt  real GLOBAL_ACTION_LOCK_SCREEN
    BootReceiver.kt              boot-completed stub for auto-start
```

## Honesty note

Every service in this codebase either performs a real OS/plugin call and
returns a genuine success, or returns a clear failure message explaining
why (missing permission, app not installed, unsupported Android version,
etc.). Nothing here fakes a result to look more finished than it is.
