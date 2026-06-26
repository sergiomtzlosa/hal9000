# HAL 9000

**A native, offline-first HAL 9000 simulation for macOS.**

<p align="center">
  <img src="docs/hal-eye.png" width="360" alt="Original red HAL 9000 eye artwork">
</p>

HAL 9000 is a fan-made desktop experience inspired by *2001: A Space Odyssey*. It is a complete
Objective-C/AppKit application: a living red eye, a scripted personality that works without a
network, optional system speech input and output, a simulated Discovery One, and an optional
OpenAI-compatible or Ollama conversation backend.

This is an original technical recreation. It contains no film footage, no copied film audio, and
no traced film artwork.

> **Fan project disclaimer:** This is an unofficial fan project. It is not affiliated with,
> sponsored by, or endorsed by the rights holders of *2001: A Space Odyssey*. “HAL 9000” and
> related marks belong to their respective owners. The code and original artwork in this
> repository are provided under the MIT license.

---

## What it is

- **100% Objective-C** — AppKit, Core Animation, and SceneKit; no Swift, SwiftUI, storyboards, xibs, or third-party runtime dependencies.
- **Offline by default** — dialogue, personality, ship telemetry, and system TTS all work without a network.
- **Optional intelligence** — connect an OpenAI-compatible endpoint or a local Ollama server. API keys live in the macOS Keychain.
- **A real desktop app** — boot sequence, main control room, cinema mode, compact floating mode, menu-bar extra, global hotkey, settings window, a built-in operations manual, and a procedural 3D HAL model and deactivation room.
- **Comfortable by default** — the main window opens centered, the eye pauses when hidden or inactive, and 3D rendering pauses when its window is closed or covered.
- **Built for macOS 13+** with the current Xcode SDK. Debug and Release local builds are supported.

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/main.png" width="820" alt="HAL 9000 main control room">
</p>

<p align="center">
  <img src="docs/screenshots/settings.png" width="700" alt="HAL 9000 settings window">
</p>

<p align="center">
  <img src="docs/screenshots/help.png" width="700" alt="HAL 9000 operations manual help window">
</p>

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/hal-3d.png" alt="Procedural 3D HAL eye"></td>
    <td width="50%"><img src="docs/screenshots/deactivation-room.png" alt="Deactivation room 3D scene"></td>
  </tr>
  <tr>
    <td align="center"><em>HAL 9000 3D model</em></td>
    <td align="center"><em>Deactivation room</em></td>
  </tr>
</table>

<p align="center">
  <img src="docs/screenshots/boot.png" width="820" alt="HAL 9000 boot sequence">
</p>

---

## Features

### The eye

The eye is drawn with layered Core Animation: a dark metallic bezel, a red radial lens, twelve
mechanical aperture blades, concentric iris rings, a bright pupil, a specular highlight, scanlines,
and sensor grain. It has distinct states for **Off**, **Boot**, **Idle**, **Listening**,
**Thinking**, **Speaking**, **Alert**, and **Muted**. It can blink, breathe, track the cursor,
pulse while HAL speaks, and widen during an alert. Reduce Motion is respected; turning it on keeps
the eye composed instead of continuously moving.

### Conversation

- Type in the input bar or use the microphone.
- Replies stream into the transcript and can be spoken by system TTS.
- App commands are recognized before the conversation engine: mute, unmute, stop, listen, settings,
  cinema, compact, diagnostics, status report, clear conversation, pod-bay requests, 3D viewer,
  and shutdown.
- The offline scripted engine loads about 25 intents from `Dialogue.json`, including greetings,
  identity, status, diagnostics, life support, chess, dreams, Daisy Bell, the pod bay, and
  in-character refusals.
- Idle observations can appear while HAL is quiet. Context depth controls how much history is
  sent to the optional LLM.
- Transcripts can be cleared or exported as Markdown or JSON.

### Voice

System voices are enumerated from `AVSpeechSynthesisVoice`, with character presets for Classic,
Calm, Precise, and Custom. Rate, pitch, volume, preview text, auto-speak, stop-on-new-message, and
the boot line are configurable. Markdown and code markers are stripped before speaking. Mute is
independent of volume.

### Listening

Push-to-talk is the default. Wake-phrase mode is opt-in and clearly marked as continuously
listening. The app requests microphone and speech-recognition permission only when needed, shows
the permission status in settings, and links to the correct Privacy pane if access is denied.
Silence timeout, maximum utterance, auto-send, on-device preference, start/stop cue, and continuous
re-arming are configurable. Audio is processed for recognition only and is never written to disk.

### Simulated ship

Ten systems are simulated: AI Core, Life Support, Reactor, Communications, Navigation, AE-35 Unit,
Pod Bay Doors, Cryo Bay, Hull Integrity, and Antenna Array. Choose a scenario, run a diagnostic
sweep, change the scenario from the sidebar, and watch the event log. Nothing in the simulation
controls real hardware or the user's computer.

### Help and onboarding

Press **⌘?**, choose **Help → HAL 9000 Help**, or click **HELP** in the main toolbar to open the
built-in operations manual. It covers quick start, voice commands, eye states, the control room,
3D records, every settings pane, keyboard shortcuts, privacy, and troubleshooting. The guide is a
dark, scrollable, selectable document and needs no network connection.

The main window centers itself on first launch (or whenever window-frame restoration is disabled).
Later launches restore the saved frame when that option is enabled.

### 3D records

Open the **3D** viewer from the toolbar or **View → 3D Viewer…** (`⌘3`). Both scenes are built
procedurally in SceneKit.

- **HAL 9000** — metallic bezels, a glass-like red lens, a bright pupil, aperture blades, a red
  internal light, studio lighting, and a subtle pedestal. Orbit with a drag, zoom with a scroll,
  and Option-drag to pan. Camera presets include Eye Detail, Three-quarter, Wide, and Reset.
- **Deactivation Room** — an original white logic-memory center with padded wall panels, ceiling
  light strips, a central console and red eye, memory racks, a stylized astronaut, a chair, and a
  reflective floor. Camera presets are Room Wide, Console, Memory Rack, and HAL Eye.

The room is intentionally a **fixed camera view**: it never auto-spins and cannot be orbited or
panned. Scroll or pinch to zoom, and use the camera presets or **RESET VIEW** to reframe it.
Auto-rotate applies only to the HAL eye model.
The visual Deactivate sequence dims the room, fades the memory modules, darkens the eye, and
displays a subtitle. Leaving the room or closing the viewer resets the scene automatically.
Deactivation is purely visual and never touches real data.

---

## Requirements

- macOS 13.0 or later.
- Xcode 16 or later. This project was built and tested with Xcode 27.2 on macOS 27.2.
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) to regenerate the project.
  The generated `HAL9000.xcodeproj` is included in the repository, so end users do not need it.
- Optional: Pillow and NumPy to regenerate the icon artwork (`python3 -m pip install pillow numpy`).
- Optional: Ollama or an OpenAI-compatible endpoint for open-ended LLM replies.

The app has no third-party runtime dependencies and is not sandboxed in v1. Microphone and speech
recognition still use the normal macOS TCC prompts.

---

## Build and run

From the repository root:

```bash
# Reproducible Release build, ad-hoc signed, copied to dist/
./scripts/build.sh

# Or a Debug build and launch
./scripts/run.sh

# Run the HALCore unit tests
./scripts/test.sh
```

Manual Xcode build:

```bash
xcodegen generate

xcodebuild \
  -project HAL9000.xcodeproj \
  -scheme HAL9000 \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build

open build/Build/Products/Debug/HAL9000.app
```

Or open `HAL9000.xcodeproj` in Xcode and press **Run**. The app is ad-hoc signed for local use;
for distribution outside your Mac, use your own Developer ID and notarization.

### Launch arguments

| Argument | Behavior |
|---|---|
| `--skip-boot` | Skip the boot overlay and go straight to the control room. |
| `--safe-mode` | Disable microphone input, LLM requests, and speech output for troubleshooting. |
| `--reset-defaults` | Ask for confirmation, then restore all settings to their defaults. The transcript and Keychain key are preserved. |

You can pass these through `open`, for example:

```bash
open build/Build/Products/Debug/HAL9000.app --args --skip-boot
```

---

## First run and permissions

1. On first launch the boot overlay appears over a dark control room. HAL warms up, reports
   diagnostics, and says “Good morning, Dave.” when speech is enabled.
2. The first time you use the microphone, macOS asks for microphone and speech-recognition access.
   HAL requests these lazily; typing always remains available.
3. If access is denied, the Listening pane shows an error and an **Open Privacy Settings** button.
   The text conversation continues to work.
4. The menu-bar icon and `⌥Space` global hotkey are available even when the main window is hidden.

To reset TCC decisions after rebuilding an ad-hoc-signed copy:

```bash
tccutil reset Microphone com.sid.hal9000
tccutil reset SpeechRecognition com.sid.hal9000
```

---

## Using HAL

### Text and speech

- Type a message and press Return.
- Click **Send** or use the mic button.
- Hold `⌥Space` (Option-Space), or press and hold the mic button, for push-to-talk. Release to
  finish. In wake-word mode, say “HAL” and then the command.
- HAL speaks replies when **Speak every HAL reply** is enabled. Use the toolbar or **Conversation →
  Stop Speaking** to interrupt.

### Useful commands

```text
status report
run diagnostics
open the pod bay doors
mute
unmute
stop speaking
listen to me
open settings
cinema mode
compact mode
3D viewer
clear conversation
quit the application
```

Pod-bay requests are refused in character unless the simulation override is enabled. Even then,
only the simulated door state changes.

### Modes and shortcuts

| Action | Shortcut / control |
|---|---|
| Settings | `⌘,` |
| Help / operations manual | `⌘?` |
| Listen | `⌘⇧L` or `⌥Space` |
| Stop speaking | `⌘.` |
| Mute / unmute | `⌘⇧M` |
| Diagnostics | `⌘⇧D` |
| Cinema mode | `⌘⇧F` |
| Compact mode | `⌘⇧C` |
| 3D viewer | `⌘3` |
| Clear conversation | `⌘K` |
| Exit cinema | `Esc` |
| Skip boot overlay | Click it or press `Esc` |
| Toggle status sidebar | `⌘⇧S` or View menu |

Cinema mode is a full-screen presentation with a large eye and optional subtitles. Compact mode
is a small floating eye window; click it to return to the control room. The menu-bar extra mirrors
the main listening, mute, settings, help, 3D, About, and quit actions.

---

## Configuration

All settings apply immediately and persist in `NSUserDefaults`. The API key is the only secret and
is stored in the Keychain, never in defaults or exported JSON.

### General

User name, boot sequence, restore conversation, save transcripts, launch at login, menu-bar icon,
confirm-before-quit, restore window frame, and start mode (`standard`, `cinema`, `compact`).

### Appearance

Eye color (`#FF2A1A` by default), eye scale, glow intensity, pulse speed, blink toggle and interval,
cursor tracking, scanlines, sensor grain, Reduce Motion mode, window opacity, always-on-top,
telemetry sidebar visibility, cinema subtitles, and font scale.

### Voice

Voice picker, character preset, rate, pitch, volume, preview button, auto-speak, stop speech on a
new message, speak the boot line, and editable preview text.

**Voice presets**

| Preset | Rate | Pitch | Character |
|---|---:|---:|---|
| Classic | 0.42 | 0.82 | Slow, low, formal |
| Calm | 0.38 | 0.90 | Slower, softer |
| Precise | 0.48 | 0.95 | Slightly quicker, clear |
| Custom | user | user | Manual sliders |

Voice quality depends on the system voices installed by macOS. The app does not clone or ship a
voice.

### Listening

Enable voice input, push-to-talk/wake-phrase/off, wake phrase, recognition locale, silence timeout,
maximum utterance, auto-send, on-device recognition preference, start/stop cue, continuous re-arm
(wake-word mode only), permission status, and Open Privacy Settings. Wake-word mode is off until
selected.

### Personality

Preset, address-as name, formality, warmth, obedience, eeriness, verbosity, humor, idle chatter and
interval, memory enabled, context depth, custom instructions, refusal style, and Reset Personality.

| Preset | Character |
|---|---|
| Classic | Formal, calm, quietly unsettling |
| Attentive | Warmer, concise, helpful |
| Unsettling | Colder, more refusals, longer pauses |
| Custom | Manual sliders |

The personality values are mapped to concise instructions in the LLM system prompt. The safety
constraint — HAL is a simulation, not a controller of real systems — is always included.

### Simulation

Scenario, tick rate, random telemetry drift, scripted events, pod-bay override, mission clock,
sound effects, alert sensitivity, ambient hum, and Reset Simulation.

| Scenario | Behavior |
|---|---|
| Discovery One — Nominal | All systems green, quiet drift |
| Jupiter Approach | Communications delay, antenna adjustments, course corrections |
| AE-35 Failure | Unit failure prediction and warning states |
| Pod Bay Lockdown | Locked doors and a higher alert posture |
| Red Alert | Multiple warnings and a more urgent eye |

### Intelligence

Optional OpenAI-compatible or Ollama engine, base URL, model, API key, temperature, maximum tokens,
timeout, SSE streaming, fallback-to-scripted, system-prompt override, Test Connection, and
**Use Offline Mode**.

### Advanced

Export/import settings JSON (secrets excluded), export transcript as Markdown or JSON, clear the
conversation, reset all settings, reveal Application Support, open logs, inspect diagnostics, and
copy diagnostics. Destructive actions ask for confirmation.

---

## Optional LLM setup

HAL remains fully usable without either option. When an LLM is selected, only text is sent to the
configured endpoint; audio is never sent, and the API key is never logged or exported.

### Ollama (local)

```bash
ollama serve
ollama pull llama3.2
```

In **Settings → Intelligence**:

- Engine: **Ollama / local**
- Base URL: `http://localhost:11434/v1`
- Model: `llama3.2`
- Stream responses: on
- Fall back to scripted mode on errors: on

No API key is needed for a local endpoint.

### OpenAI-compatible endpoint

- Engine: **OpenAI-compatible**
- Base URL: `https://api.openai.com/v1`
- Model: your model ID
- API key: save it with **Save Key**; it is stored in the Keychain
- Use **Test Connection** to send a small non-transcript request

The client accepts any OpenAI-compatible `/chat/completions` endpoint, including local servers
that expose the same shape. If the request fails, times out, or returns an unreadable response,
HAL falls back to the scripted engine when fallback is enabled.

---

## Architecture

```text
HALCore/                  Foundation-only static library
  HALConfiguration        Defaults, persistence, JSON import/export
  HALMemoryStore          Transcript storage, capping, corrupt-file recovery
  HALScriptedEngine       Offline intent matching and response selection
  HALCommandRouter        App commands before conversation
  HALConversationEngine   Engine protocol
  HALLLMClient            OpenAI-compatible client with SSE streaming
  HALSSEParser            Boundary-safe SSE parsing
  HALShipSimulator        Systems, scenarios, events, diagnostics
  HALPromptBuilder        Personality and safety prompt construction
  HALKeychainStore        API key storage

HAL9000/                  AppKit application
  App/                    Lifecycle, menus, menu bar, hotkey, launch at login
  Services/               TTS, speech recognition, conversation, boot sequence
  UI/                     Eye, chat, sidebar, settings, help, cinema, 3D viewer
  Resources/              Dialogue.json and HAL9000.icns

HAL9000Tests/             XCTest logic tests for HALCore
```

The `HALCore` target has no AppKit dependency, so configuration, dialogue, SSE parsing, memory,
prompt building, and simulation behavior are testable without opening a window or asking for
microphone permission.

### Data locations

```text
~/Library/Application Support/HAL9000/conversation.json
~/Library/Application Support/HAL9000/exports/
~/Library/Application Support/HAL9000/logs/
```

The API key is stored in the login Keychain under service `com.sid.hal9000` and account
`llm-api-key`. A corrupt conversation file is renamed with a `.corrupt-<timestamp>` suffix and the
app starts with a fresh transcript. History is capped at 500 stored and 200 displayed messages.

### Threading

UI and AppKit work stays on the main thread. Speech-recognition and LLM callbacks are delivered to
the main queue before updating UI. The simulation uses a main-run-loop timer. Transcript writes are
serialized. Long-lived blocks use weak references and outstanding LLM tasks are cancelled when a
new response begins. System voice enumeration runs on a background queue and is cached. The eye
animation stops when its window is hidden, minimized, covered, or the app is inactive; SceneKit
rendering pauses the same way when the 3D viewer is not visible. Chat scroll/layout requests are
coalesced so restoring a long transcript or streaming a fast reply cannot flood the main queue.

---

## Icon generation

The app icon and README hero artwork are generated from original geometry by `scripts/make_icon.py`.
The generated files are committed, so users do not need Pillow:

```bash
python3 scripts/make_icon.py
```

This writes:

- `docs/hal-eye.png` — 1024×1024 hero image.
- `HAL9000/Resources/AppIcon.iconset/` — the standard macOS iconset.
- `HAL9000/Resources/HAL9000.icns` — the bundle icon.

Validate it with:

```bash
file HAL9000/Resources/HAL9000.icns
sips -g pixelWidth -g pixelHeight docs/hal-eye.png
iconutil -c iconset HAL9000/Resources/HAL9000.icns -o /tmp/hal-verify.iconset
```

The `.icns` is included in Copy Bundle Resources, and `CFBundleIconFile` points to it. It appears in
Finder, the Dock, About, and the built `.app`.

---

## Tests and verification

```bash
./scripts/test.sh
```

The XCTest suite covers configuration defaults and JSON round-trips, scripted intent priority and
fallbacks, SSE chunk boundaries and `[DONE]`, transcript capping and corrupt-file recovery, prompt
contents and the safety constraint, command routing, and simulator scenarios. The tests run against
`HALCore` only; no app host, GUI, or microphone permission is required. `scripts/test.sh` builds the
bundle with `build-for-testing` and runs `xcrun xctest` directly, so it also works from headless or
remote sessions where the GUI test runner is unavailable.

Additional build checks:

```bash
plutil -lint HAL9000/Info.plist
file HAL9000/Resources/HAL9000.icns
xcodebuild -project HAL9000.xcodeproj -scheme HAL9000 \
  -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
codesign --verify --deep --strict --verbose=2 dist/HAL9000.app
```

### Manual checklist

- [ ] Boot overlay appears, reaches full red, and cross-fades to the main window.
- [ ] Eye states and speaking pulse are visible; Reduce Motion suppresses continuous motion.
- [ ] Text conversation works without a network.
- [ ] TTS uses the selected voice, rate, pitch, and volume; preview, mute, and stop work.
- [ ] Push-to-talk requests permission once and degrades cleanly if denied.
- [ ] All eight settings panes open without a visible stall, apply immediately, and persist across relaunch.
- [ ] Sidebar text, pop-up buttons, and other system controls remain legible in the dark theme.
- [ ] The first-launch window is centered; later launches restore the saved frame when enabled.
- [ ] **Help → HAL 9000 Help** (`⌘?`) opens a readable, scrollable operations manual.
- [ ] Opening Voice or Advanced settings does not block the main thread while system voices load.
- [ ] Settings export excludes the API key; import validates URLs and model values.
- [ ] Keychain save/clear and Test Connection work; an invalid endpoint falls back to scripted mode.
- [ ] Scenario changes reset telemetry; diagnostics complete and update the event log.
- [ ] Cinema/compact toggle back to standard; closing cinema restores the main window.
- [ ] 3D HAL orbit and camera presets work; auto-rotate can be toggled.
- [ ] The deactivation room camera is fixed and does not spin; scroll zoom, presets, and RESET VIEW work.
- [ ] Deactivate fades the room and eye; leaving the room resets every node and light.
- [ ] `--safe-mode` disables microphone, LLM, and audio but leaves text conversation usable.
- [ ] Menu bar, `⌥Space`, menus, About, and quit/reopen behave correctly.

---

## Troubleshooting

### HAL does not speak

- Check **Voice → Speak every HAL reply** and the volume slider.
- Check that HAL is not muted (toolbar/menu bar).
- Open **Settings → Voice** and choose a different installed voice. Voice availability depends on
  macOS; some downloadable voices may not be installed.
- Try `--safe-mode` only for diagnostics; it intentionally disables speech.

### Microphone or speech recognition does not work

- Confirm the app has Microphone and Speech Recognition access in System Settings → Privacy &
  Security.
- Reset TCC after rebuilding an ad-hoc-signed copy:
  `tccutil reset Microphone com.sid.hal9000` and
  `tccutil reset SpeechRecognition com.sid.hal9000`.
- On-device recognition may not be available for every locale or Mac. Turn the on-device preference
  off to allow the system fallback.
- Text chat works independently of microphone permissions.

### The icon is missing

- Confirm `HAL9000/Resources/HAL9000.icns` exists and is included in the app bundle.
- Rebuild after running `python3 scripts/make_icon.py`.
- If Finder still shows a cached icon, relaunch Finder or rebuild the Launch Services database.

### Launch at login fails

`SMAppService` registration can fail for an ad-hoc-signed app outside `/Applications`. HAL catches
the error, keeps the setting off, and explains the failure. For reliable login-item behavior, sign
with a stable identity and place the app in `/Applications`.

### LLM requests fail

- Check the base URL; it should normally end in `/v1` and the client appends
  `/chat/completions`.
- Confirm the model name is available on the server.
- For Ollama, verify `ollama serve` is running and the model has been pulled.
- Use **Test Connection**; errors are shown inline and never include the API key.
- If the endpoint is unreachable, enable fallback-to-scripted or choose **Use Offline Mode**.

### Layout or readability issues

The app deliberately uses the dark Aqua appearance so custom dark panels and system controls stay
legible together. If a control looks wrong, include the pane name and a screenshot when reporting
it. The settings pane content is scrollable at the minimum window size.

### 3D viewer is slow

Open **Settings → Appearance → 3D records** and choose **Medium** render quality. The room is a
fixed camera view with scroll/pinch zoom only; in the HAL scene, orbit, zoom, and pan are
intentionally user-controlled.

---

## Privacy and security

- HAL works offline. There are no analytics, telemetry, trackers, or background network calls.
- Only text is sent to an LLM endpoint that you explicitly configure. Audio is never sent.
- Microphone audio is processed only while listening and is never written to disk.
- The API key is stored in the macOS Keychain and is excluded from defaults, logs, exports, and
  diagnostics.
- Transcripts and exports stay in local Application Support. You can clear them at any time.
- The simulation never controls real hardware, home automation, spacecraft, or the user's Mac.
  Pod bay, deactivation, and ship-system actions are fictional.
- `--safe-mode` disables microphone input, LLM access, and speech output for troubleshooting.

---

## License

Original code and original artwork are released under the MIT license. See [LICENSE](LICENSE).

This repository is a fan project and is not affiliated with or endorsed by the rights holders of
*2001: A Space Odyssey*. “Daisy Bell” is in the public domain. No film stills, logos, or copied
film audio are included.
