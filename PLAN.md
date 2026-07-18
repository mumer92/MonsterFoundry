# Monster Foundry — Hackathon Build Plan

## Product promise

A child draws something—monster, robot, animal, vehicle, person-like doodle, or impossible object—**or describes it in a sentence**. The app treats that idea as the source of truth, discovers a funny personality, renders it in a chosen physical art material, gives it a voice, and can turn its adventure into a saved movie.

```text
Draw or describe -> Direct the magic -> Reveal -> Hear and play -> Continue in My Creations
```

The five judging goals stay visible in every decision:

- **Visual:** a large canvas, tactile art materials, and an immersive reveal.
- **Interesting:** the child's strange marks remain recognisable instead of being replaced.
- **Story:** every result has a name, personality, harmless fear, silly food, home, and origin.
- **Fun:** judges can draw, randomise a scene, hear the character, tap it, replay a movie, and make a next chapter.
- **Easy to judge:** the whole path is labelled **Draw → Direct → Play**, with one obvious primary action per screen.

## Final experience

### 1. Create the creature

The opening screen supports two equally clear inputs:

- **Draw:** a large PencilKit canvas for Apple Pencil or finger.
- **Use a prompt:** a large writing pad for a short creature description.

The drawing studio provides Fountain, Ink, Monoline, Marker, Sketch, Crayon, Watercolor, and Eraser tools, plus six named colour palettes with 50 swatches, a full custom colour picker, size, flow, undo, redo, and protected clear.

Portrait uses a wide vertical studio. Landscape turns the canvas into a nearly full-height stage with a compact tool rail beside it.

### 2. Direct the magic

Before any paid generation begins, the child explicitly chooses the creative result.

#### Art material

- Ink drawing
- Pencil sketch
- Crayon
- Watercolor
- Marker
- Paper cutout
- Clay
- Storybook

#### Sketch fidelity

- **Faithful:** preserve every wobble, proportion, and feature count.
- **Balanced:** preserve the silhouette while gently refining forms.
- **Creative:** preserve the idea while exploring lighting and environment.

#### Output

- **Fast illustrated postcard:** image and funny identity.
- **Short story:** illustration, longer tale, and spoken greeting.
- **Animated movie:** a one-call **Quick 8 sec** scene, or a 10, 20, or 30-second scene reel.
- **Full adventure pack:** image, story, voice, and movie.

Every output also offers a story shape:

- **Short (default):** about 60 words for a fast judge demo.
- **Medium:** about 160 words with a complete problem and payoff.
- **Long:** about 320 words as a polished read-aloud chapter.

The child may optionally supply a background, emotional goal, or story seed. Leaving it empty asks the model to invent from the drawing.

For movie outputs, the child can describe a scene or press **Surprise me**. Gemini turns the direction into four coherent visual beats. The randomiser is local and immediate, so a judge can see the idea change before generation begins.

### 3. Awaken

The app sends the sketch or prompt plus the complete creative brief to Gemini. One structured `MonsterProfile` becomes the source of truth for every output:

```json
{
  "name": "Bloop-Square",
  "species": "Cube-Cyclops",
  "visibleTraits": ["one giant eye", "six roller skates"],
  "personality": "optimistic and spectacularly clumsy",
  "home": "The Great Graph-Paper Plains",
  "favoriteFood": "dandelion-flavoured bubblegum clouds",
  "fear": "perfectly flat banana peels",
  "backstory": "...",
  "greeting": "...",
  "firstAction": "...",
  "imagePrompt": "...",
  "motionPrompt": "...",
  "scenePrompts": ["scene one", "scene two", "scene three", "scene four"]
}
```

The image request includes the same profile, original input, material, and fidelity. This keeps the story, appearance, and motion direction consistent.

### 4. Reveal and play

The reveal is designed as the hackathon payoff:

- the generated world is the largest visual on screen;
- landscape uses the available width and height as an immersive media stage;
- portrait keeps the complete 16:9 result full-width;
- the original sketch or written idea remains pinned in the corner;
- the story and traits are visible beside or below the image;
- one tap creates expressive OpenAI narration for the full story, saves the MP3, and clearly labels the voice as AI-generated;
- if the OpenAI key or service is unavailable, the same control falls back to an Apple system voice;
- tapping the character produces a physical reaction and haptic;
- a generated movie plays inline with normal playback controls and looping.

The illustration appears before a slower movie finishes. Movie progress is shown as **Scene 1 of 2**, for example, while the image, story, voice, and touch reaction remain usable.

### 5. Save and revisit

Every finished result is saved automatically to **My Creations** on the device:

- structured profile and creative choices in a JSON index;
- original sketch and generated hero image as local files;
- completed narration MP3 and movie MP4 copied into the app's Application Support directory.

The gallery works in portrait and landscape. A child can search by name or story, filter all/movies/stories/postcards, sort newest or oldest, reopen an old creation, hear its cached narration, tap it, and play its saved movie. **Next chapter** and **New scene** branch any saved creation while preserving its identity. There is no account, database, cloud storage service, or backend.

## Video duration strategy

Veo creates short clips, not a direct 30-second result. The app therefore uses 8-second image-to-video scenes and joins them locally with AVFoundation:

| Chosen length | Generated scenes | Local final movie |
| --- | ---: | ---: |
| Quick 8 seconds | 1 × 8-second clip | saved directly as an 8-second movie |
| 10 seconds | 2 × 8-second clips | trimmed to 10 seconds |
| 20 seconds | 3 × 8-second clips | trimmed to 20 seconds |
| 30 seconds | 4 × 8-second clips | trimmed to 30 seconds |

Each scene starts from the same hero image and uses a different AI-authored scene beat. This produces a tiny montage while protecting character consistency. Longer choices cost more and take longer, so **Quick 8 sec is the demo default**.

## Selected architecture

| Purpose | Technology |
| --- | --- |
| Drawing | PencilKit |
| App UI and adaptive layout | SwiftUI |
| Character analysis and structured story | `gemini-3.1-flash-lite` |
| Sketch/prompt-to-image | `gemini-3.1-flash-lite-image` |
| Image-to-video scenes | `veo-3.1-lite-generate-preview` |
| Join and trim scenes | AVFoundation |
| Story narration | OpenAI `gpt-4o-mini-tts` (`marin`) |
| Voice fallback | `AVSpeechSynthesizer` |
| Playback | `AVPlayerViewController` |
| Saved creations | JSON + images/MP3/MP4 in Application Support |

The root view owns a small experience state:

```swift
enum ExperiencePhase {
    case drawing
    case customizing
    case awakening
    case reveal
    case gallery
}
```

`MonsterAPIClient` performs direct async Gemini requests. `CreationLibrary` owns local file persistence. `VideoComposer` concatenates and trims generated scenes. SwiftUI `.task(id:)` starts cancellable generation work.

## Direct API contract — no backend

The development app reads keys from its bundled `MonsterFoundry/keys.plist` and calls Google and OpenAI directly:

1. `POST /v1beta/interactions` creates the structured character and scene plan.
2. A second `POST /v1beta/interactions` creates the sketch-preserving hero image.
3. `POST /v1beta/models/veo-3.1-lite-generate-preview:predictLongRunning` starts each eight-second scene.
4. The app polls the operation, downloads each MP4, joins the requested reel, and saves the final movie locally.
5. On demand, `POST /v1/audio/speech` creates expressive story narration and the app saves the MP3 locally.

### API keys

Required:

- `gemini_api_key`
- billing and Veo access enabled for the same Google AI project

Recommended for AI narration:

- `openai_api_key`

No separate voice key is needed: narration uses the existing OpenAI key. Without it, story playback automatically uses the on-device Apple voice. No additional key is needed for PencilKit, playback, AVFoundation, haptics, or local storage.

Because this is a no-backend hackathon build, both API keys are extractable from the app bundle. Do not distribute valuable production keys in a public build.

## Atelier inspiration used

Atelier was reviewed read-only. Monster Foundry adopts its strongest interaction ideas without copying its implementation:

- canvas-first composition;
- a tactile horizontal material/tool rail;
- named colour families, horizontal swatches, and a custom colour control;
- searchable history with meaningful result filters;
- explicit Faithful, Balanced, and Creative control;
- explicit output selection before generation;
- generation begins only after the primary action is pressed.

Monster Foundry keeps its own playful visual language, judge path, PencilKit implementation, story pipeline, and saved gallery.

## Two-hour hackathon priority

| Time | Outcome |
| --- | --- |
| 0–15 min | Verify one Gemini key for profile, image, and Veo |
| 15–40 min | Large PencilKit canvas and prompt input |
| 40–62 min | Material, fidelity, output, and scene direction screen |
| 62–85 min | Structured profile, image generation, awakening, and reveal |
| 85–102 min | Voice, touch reaction, one 8-second Veo scene |
| 102–112 min | Multi-scene composer and local My Creations shelf |
| 112–120 min | Portrait/landscape checks, failures, demo rehearsal, code freeze |

If the demo must be made safer, use **Fast illustrated postcard** during judging and show a previously saved movie from **My Creations**. This makes the result immediate while still proving the complete feature.

## Definition of done

- A judge can draw or type any character or imaginative subject.
- The canvas is large and usable in portrait and landscape.
- All eight requested art materials are selectable.
- Postcard, story, movie, and full-pack outputs are explicit.
- Movie users can choose Quick 8 sec, 10, 20, or 30 seconds and describe or randomise scenes.
- The generated creature remains recognisable from the original input.
- The reveal includes a funny name, personality, story, greeting, and visible traits.
- Short, medium, and long stories follow the child's optional background idea.
- The child can hear AI narration, with a labelled Apple fallback, and touch the character.
- Video failure never blocks the image/story reveal.
- Finished creations are searchable, sortable, saved locally, and reopen from My Creations.
- Any saved creation can branch into a next chapter or a new movie scene.
- No backend is required.

## 45-second judge demo

1. Ask a judge to draw one strange feature or type one funny sentence.
2. Press **Next: Direct the Magic**.
3. Let the judge pick **Crayon**, **Faithful**, and an output.
4. For a movie, press **Surprise me** and show the generated scene idea.
5. Press **Bring It Alive**.
6. Reveal the result, compare it with the pinned original, and play its greeting.
7. Tap the character to make it react.
8. Open **My Creations**, filter **Movies**, replay one, then press **Next chapter**.

Pitch:

> A child invents first. AI does not replace the scribble—it discovers the character already hiding inside it, then helps that character speak, play, and star in its own tiny movie.
