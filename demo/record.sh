#!/bin/bash
# Record the reliable Monster Foundry judge demo to an MP4.
#
# Uses the local XcodeBuildMCP recorder and Maestro; no cloud renderer. The
# post-process trim guarantees a deliverable shorter than 90 seconds.
#
# Usage:
#   ./demo/record.sh
#   ./demo/record.sh <SIM_UDID> <out.mp4>
set -euo pipefail

DEFAULT_UDID="305A911D-F2E2-4E4B-9D3A-7BBAA3234924" # iPad Air 11-inch (M4), iOS 27
UDID="${1:-$DEFAULT_UDID}"
DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"
OUT="${2:-$DIR/monsterfoundry-demo.mp4}"
FLOW="$DIR/demo-flow.yaml"
CAPPED_OUT="${OUT%.*}.capped.mp4"

echo "▶ Building and launching on simulator: $UDID"
xcodebuildmcp simulator build-and-run \
  --workspace-path "$PROJECT_ROOT/MonsterFoundry.xcworkspace" \
  --scheme MonsterFoundry \
  --simulator-id "$UDID" \
  --configuration Debug

echo "● Recording -> $OUT"
xcodebuildmcp simulator record-video \
  --simulator-id "$UDID" \
  --start true \
  --fps 30 \
  --output-file "$OUT"

echo "▶ Running judge flow"
set +e
maestro test --device "$UDID" "$FLOW"
FLOW_STATUS=$?
set -e

echo "■ Finalising recording"
xcodebuildmcp simulator record-video --simulator-id "$UDID" --stop true

if [[ ! -s "$OUT" ]]; then
  echo "Recording was not created: $OUT" >&2
  exit 1
fi

# Even if an external service is unusually slow, the final deliverable never
# exceeds the 90-second requirement.
ffmpeg -hide_banner -loglevel error -y -i "$OUT" -t 89 -c copy "$CAPPED_OUT"
mv "$CAPPED_OUT" "$OUT"

DURATION=$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 "$OUT")
echo "✅ Saved: $OUT (${DURATION}s)"

if [[ $FLOW_STATUS -ne 0 ]]; then
  echo "⚠ The UI flow ended early; inspect the MP4 before presenting." >&2
fi
