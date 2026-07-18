# Monster Foundry

Draw anything imaginative or describe it in a sentence. Monster Foundry preserves the child's idea, discovers a personality and proper story, renders it in a chosen art material, gives it a voice, and can create a saved 10–30 second movie.

```text
Draw or describe -> Direct the magic -> Reveal -> Hear and play -> My Creations
```

## Implemented

- Native SwiftUI iPad/iPhone app targeting iOS 17+
- Adaptive portrait and landscape layouts
- Large PencilKit canvas with Apple Pencil and finger input
- Fountain, ink, monoline, marker, sketch, crayon, watercolor, and eraser tools
- Six named palettes, 50 colour swatches, a custom colour picker, size, flow, undo, redo, and protected clear
- Written-prompt alternative to drawing
- Ink, pencil, crayon, watercolor, marker, paper-cutout, clay, and storybook generation looks
- Faithful, Balanced, and Creative sketch interpretation
- Illustrated postcard, short story, animated movie, and full-adventure-pack outputs
- Short (default), medium, and long story lengths with an optional background/story direction
- Custom or randomly suggested movie scenes
- One-call **Quick 8 sec** animation plus 10, 20, and 30-second movie choices built from coherent eight-second Veo scenes
- Direct Gemini character/story and image generation
- Direct Veo generation, authenticated MP4 download, AVFoundation composition, and inline playback controls
- Expressive OpenAI story narration with a visible AI-voice disclosure and automatic Apple voice fallback
- Touch reaction and haptics
- Device-local **My Creations** history with search, type filters, newest/oldest sorting, saved images, narration, and movies
- **Next chapter** and **New scene** branches for every saved creation
- Offline reveal if Gemini is unavailable
- No backend, Worker, database, account, or cloud storage service

The complete product and hackathon plan is in [PLAN.md](./PLAN.md).
The last-minute judge runbook is in [DEMO_CHECKLIST.md](./DEMO_CHECKLIST.md).

## Architecture

```text
iOS app
  PencilKit + SwiftUI
       |
       +-- gemini-3.1-flash-lite       structured character + scene plan
       +-- gemini-3.1-flash-lite-image generated hero world
       +-- Veo 3.1 Lite                8-second movie scenes
       +-- AVFoundation                save 8-second clips or join/trim to 10, 20, or 30 seconds
       +-- OpenAI gpt-4o-mini-tts      expressive story narration
       +-- AVSpeechSynthesizer          narration fallback
       +-- AVPlayerViewController       playback controls + looping
       +-- Application Support          local My Creations library
```

All feature code lives in `MonsterFoundryPackage/Sources/MonsterFoundryFeature`.

## Key

`MonsterFoundry/keys.plist` must contain:

```xml
<key>gemini_api_key</key>
<string>YOUR_KEY</string>
<key>openai_api_key</key>
<string>YOUR_OPENAI_KEY</string>
```

`gemini_api_key` drives the core character, image, and Veo pipeline; Veo access and billing must be enabled for that Google AI project. `openai_api_key` enables the expressive story narrator. If the OpenAI key is absent or narration fails, the app automatically uses an Apple system voice, so no additional voice key is required.

This is deliberately a direct-API, no-backend hackathon build. Bundled keys can be extracted, so do not publish or distribute valuable production credentials.

## Run

Open `MonsterFoundry.xcworkspace`, select the `MonsterFoundry` scheme, and run on an iPad/iPhone simulator or device with internet access.

## Demo advice

Generate and save one movie before judging. During the live demo, use **Fast illustrated postcard** for the quickest reveal, then open **My Creations**, filter **Movies**, and replay the prepared result. Finish by pressing **Next chapter** to show that a child's creation can grow instead of disappearing after one generation.
