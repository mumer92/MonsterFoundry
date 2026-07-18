<div align="center">

# 🧟 Monster Foundry

**Draw a doodle — or describe one in a sentence — and watch it come alive with a name, a personality, a story, a voice, and its own little movie.**

Monster Foundry keeps your original idea as the source of truth: it discovers a character, renders it in a chosen art material, narrates its tale, and can save a 10–30 second movie of its adventure.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.1-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI-green)
![Architecture](https://img.shields.io/badge/architecture-no%20backend-lightgrey)

</div>

```text
Draw or describe  ➜  Direct the magic  ➜  Reveal  ➜  Hear & play  ➜  My Creations
```

---

## Demo

https://github.com/mumer92/MonsterFoundry/raw/main/demo/demo.mp4

<video src="https://github.com/mumer92/MonsterFoundry/raw/main/demo/demo.mp4" controls muted playsinline width="100%"></video>

> If the player doesn't load, [▶️ watch / download the demo here](./demo/demo.mp4).

---

## Table of Contents

- [Demo](#demo)
- [What it does](#what-it-does)
- [Features](#features)
- [How it works](#how-it-works)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Security & privacy](#security--privacy)
- [Documentation](#documentation)
- [License](#license)

---

## What it does

Hand-drawn doodles are usually replaced by AI, not respected by it. Monster Foundry does the opposite: your strange marks stay recognisable while the app builds a whole world around them.

1. **Create** — draw on a large PencilKit canvas (Apple Pencil or finger) *or* type a one-sentence description.
2. **Direct** — pick the art material, how faithful the result should be, and what to make (postcard, story, movie, or the full pack).
3. **Awaken** — the sketch plus the creative brief become a single structured character profile that drives every output.
4. **Reveal & play** — an immersive reveal shows the generated world, story, and traits; tap to hear expressive narration, tap the character for a reaction, and watch its movie inline.
5. **Revisit** — every creation is saved locally to **My Creations**, where it can be searched, replayed, and *continued* with a next chapter or a new scene.

## Features

**Canvas & input**
- Large adaptive PencilKit canvas with portrait & landscape layouts
- Fountain, ink, monoline, marker, sketch, crayon, watercolor, and eraser tools
- Six named palettes, 50 swatches, custom colour picker, size, flow, undo/redo, protected clear
- Written-prompt alternative for anyone who'd rather describe than draw

**Generation**
- Eight art materials: ink, pencil, crayon, watercolor, marker, paper cutout, clay, storybook
- Faithful / Balanced / Creative sketch interpretation
- Outputs: illustrated postcard · short story · animated movie · full adventure pack
- Short / medium / long story lengths with an optional story-direction seed
- **Quick 8 sec** one-call animation, plus 10 / 20 / 30-second movies built from coherent 8-second scenes

**Voice & playback**
- Expressive OpenAI narration with a visible AI-voice disclosure
- Automatic Apple system-voice fallback if narration is unavailable
- Inline movie playback with looping and standard controls
- Touch reactions and haptics

**Library**
- Device-local **My Creations** history — no account, database, or cloud
- Search, type filters, newest/oldest sorting, cached images / narration / movies
- **Next chapter** and **New scene** branches that preserve a creation's identity
- Offline reveal path if the model is unavailable

## How it works

Monster Foundry is a **direct-API, no-backend** app. All feature code lives in `MonsterFoundryPackage/Sources/MonsterFoundryFeature`.

```text
iOS app (SwiftUI + PencilKit)
      │
      ├─ Gemini (flash-lite)          structured character + scene plan
      ├─ Gemini (flash-lite-image)    generated hero world
      ├─ Veo 3.1 Lite                 8-second movie scenes
      ├─ AVFoundation                 save / join / trim to 10, 20, 30 s
      ├─ OpenAI gpt-4o-mini-tts       expressive story narration
      ├─ AVSpeechSynthesizer          narration fallback
      ├─ AVPlayerViewController       playback controls + looping
      └─ Application Support          local My Creations library
```

The sketch (or prompt) plus the full creative brief produce one structured `MonsterProfile` — name, species, visible traits, personality, home, favourite food, fear, backstory, greeting, image prompt, motion prompt, and scene prompts. That single profile is the source of truth for the image, story, voice, and movie, keeping everything consistent.

## Tech stack

| Area | Choice |
|------|--------|
| Language | Swift 6.1 (strict concurrency) |
| UI | SwiftUI (MV pattern, no ViewModels) |
| Drawing | PencilKit |
| Media | AVFoundation / AVKit |
| Min OS | iOS 17.0 |
| Structure | Xcode workspace + Swift Package (`MonsterFoundryPackage`) |
| Testing | Swift Testing |
| Character / image / video | Google Gemini + Veo |
| Narration | OpenAI TTS (with Apple voice fallback) |

## Getting started

### Prerequisites

- macOS with **Xcode 16+**
- An iPhone/iPad simulator or device on **iOS 17+** with internet access
- A **Google Gemini** API key with **Veo access and billing enabled**
- *(Optional)* an **OpenAI** API key for expressive narration

### 1. Clone

```bash
git clone <your-repo-url>
cd codex-hackathon-2
```

### 2. Enable the git hooks (recommended)

This repo ships a pre-commit hook that blocks secrets (API keys) and your Apple Team ID from ever being committed. Git can't auto-enable hooks on clone, so run once:

```bash
git config core.hooksPath .githooks
```

### 3. Add your API keys

Create `MonsterFoundry/keys.plist` (this file is **gitignored** and must never be committed):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>gemini_api_key</key>
    <string>YOUR_GEMINI_KEY</string>
    <key>openai_api_key</key>
    <string>YOUR_OPENAI_KEY</string>
</dict>
</plist>
```

- `gemini_api_key` drives the character, image, and Veo pipeline (Veo billing must be enabled).
- `openai_api_key` enables the narrator. If it's missing, the app falls back to an Apple system voice — no extra key required.

### 4. Set your signing team

The Apple Developer Team ID is kept out of the repo. Copy the template and add your own:

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
# edit Config/Local.xcconfig and set DEVELOPMENT_TEAM = <YOUR_TEAM_ID>
```

`Config/Local.xcconfig` is gitignored. Find your Team ID in **Xcode ▸ Settings ▸ Accounts** or at [developer.apple.com/account](https://developer.apple.com/account).

### 5. Run

Open **`MonsterFoundry.xcworkspace`**, select the **`MonsterFoundry`** scheme, and run on a simulator or device.

> 💡 **Demo tip:** generate and save one movie beforehand. During a live demo, use **Fast illustrated postcard** for the quickest reveal, then open **My Creations ▸ Movies** and replay the prepared result. Finish with **Next chapter** to show a creation can grow instead of disappearing.

## Project structure

```text
codex-hackathon-2/
├── Config/                       # XCConfig build settings + entitlements
│   ├── Shared / Debug / Release / Tests.xcconfig
│   ├── Local.xcconfig.example    # template for your Team ID (copy → Local.xcconfig)
│   └── MonsterFoundry.entitlements
├── MonsterFoundry.xcworkspace/   # open this
├── MonsterFoundry.xcodeproj/     # thin app shell
├── MonsterFoundry/               # @main entry point, assets, keys.plist (local)
├── MonsterFoundryPackage/        # all features & business logic
│   └── Sources/MonsterFoundryFeature/
├── MonsterFoundryUITests/
├── .githooks/pre-commit          # secret / Team ID guard
└── PLAN.md                       # full product & hackathon plan
```

## Security & privacy

- **No backend, database, account, or cloud storage.** Everything lives on the device.
- **Secrets are never committed** — `keys.plist` and `Config/Local.xcconfig` are gitignored, and a pre-commit hook rejects any commit that would introduce an API key or an Apple Team ID.
- This is deliberately a **direct-API hackathon build**. Bundled keys can be extracted from a shipped app, so **do not embed valuable production credentials** in a distributed build.

## Documentation

- 📘 [PLAN.md](./PLAN.md) — the complete product and hackathon build plan

## License

No license file is currently included. Until one is added, this project is provided as-is for the hackathon; contact the author before reuse.
