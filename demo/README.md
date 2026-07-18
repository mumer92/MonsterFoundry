# Recording the Monster Foundry demo

The repeatable default capture uses the **iPad Air 11-inch (M4)** simulator
(`305A911D-F2E2-4E4B-9D3A-7BBAA3234924`) and always produces a final file under
90 seconds. It re-encodes to an 88-second maximum and shows the strongest reliable route: idea -> crayon postcard ->
story voice -> touch reaction -> saved creation -> next chapter.

## Prerequisites

- Valid `keys.plist` (Gemini key for the postcard; OpenAI key for narration).
- XcodeBuildMCP and Maestro 2.3.0 (already installed). The recording script
  builds and installs the current app itself.

## Option A — scripted + recorded

Builds the app, runs the Maestro flow, records the screen, then hard-trims the
final MP4 to 88 seconds:

```bash
./demo/record.sh                 # -> demo/monsterfoundry-demo.mp4
./demo/record.sh <UDID> out.mp4  # custom device / filename
```

The flow (`demo-flow.yaml`) does: **prompt a creature -> Direct the Magic
(Crayon · Faithful · Fast illustrated postcard · Short) -> Awaken -> Reveal ->
hear the story -> tap the character -> My Creations -> Next chapter.**

> It does not make a live Veo request: a Veo job can take longer than the demo
> budget. Once a finished Veo clip is saved in My Creations, make a separate
> movie-replay recording for the optional long-form showcase.

## Option B — manual drawing take

Automating freeform PencilKit drawing looks crude, so for a take that shows a
hand-drawn monster, record while you draw and tap through:

```bash
xcodebuildmcp simulator record-video \
  --simulator-id 305A911D-F2E2-4E4B-9D3A-7BBAA3234924 \
  --start true --fps 30 --output-file demo/monsterfoundry-demo.mp4
```

Then draw a monster, tap **Next: Direct the Magic**, choose the postcard route,
press **Bring It Alive**, hear the story, tap the character, open **My
Creations**, and choose **Next chapter**. Stop recording with:

```bash
xcodebuildmcp simulator record-video \
  --simulator-id 305A911D-F2E2-4E4B-9D3A-7BBAA3234924 \
  --stop true --output-file demo/monsterfoundry-demo.mp4
```

## Tips

- Iterate without recording: `maestro test demo/demo-flow.yaml`.
- Inspect element ids live: `maestro studio`.
- The script prints the final duration: it must be less than 90 seconds.
