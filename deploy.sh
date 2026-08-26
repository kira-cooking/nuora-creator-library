#!/bin/bash
# publishes the nuora creator library to github pages.
# safe to re-run: the first run creates the repo, later runs just push updates.
set -e

cd "$(dirname "$0")"
REPO="nuora-creator-library"
USER="$(gh api user --jq .login)"

printf '# nuora creator library\n\nbreakdowns of winning videos for nuora creators. every entry is\nwatched in full (transcript, word-level timings, frame by frame),\nthen rebuilt into a shot list for our products.\n\nlive: https://%s.github.io/%s/\n\n- 12 - the 44-second mirror - @tito_from_texas, magnesium complex\n' "$USER" "$REPO" > README.md

if [ ! -d .git ]; then
  git init -q -b main
fi
git add -A
git commit -q -m "breakdown 12: the 44-second mirror" || echo "(nothing new to commit)"

if gh repo view "$USER/$REPO" >/dev/null 2>&1; then
  echo "repo exists, pushing update..."
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USER/$REPO.git"
  git push -q -u origin main
else
  echo "creating public repo..."
  gh repo create "$REPO" --public --source=. --push \
    --description "Breakdowns of winning videos for Nuora creators"
fi

echo "enabling github pages..."
gh api -X POST "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || echo "(pages already configured)"

URL="https://$USER.github.io/$REPO/"
echo
echo "================================================================"
echo "  building. github pages takes ~60s on the first deploy."
echo "  your public link:"
echo "  $URL"
echo "================================================================"
echo
# verify the NEW file is live, not just that some page returns 200.
# a status check alone always passes after the first deploy and tells you nothing.
STAMP=$(shasum -a 1 index.html | cut -c1-12)
echo "waiting for this exact build to go live (fingerprint $STAMP)..."
for i in $(seq 1 30); do
  LIVE=$(curl -s -H "Cache-Control: no-cache" "$URL?cb=$i$$" | shasum -a 1 | cut -c1-12)
  if [ "$LIVE" = "$STAMP" ]; then
    echo
    echo "LIVE and matching your local file - $URL"
    echo
    echo "your browser will still show the old copy for up to 10 minutes."
    echo "hard-reload with Cmd+Shift+R, or open $URL?v=$STAMP"
    exit 0
  fi
  sleep 10
done
echo "pages is still rebuilding. re-check $URL in a minute with Cmd+Shift+R."
