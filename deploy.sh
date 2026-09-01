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
MATCHED=0
for i in $(seq 1 30); do
  LIVE=$(curl -s -H "Cache-Control: no-cache" "$URL?cb=$i$$" | shasum -a 1 | cut -c1-12)
  if [ "$LIVE" = "$STAMP" ]; then MATCHED=1; break; fi
  sleep 10
done

if [ "$MATCHED" != "1" ]; then
  echo "pages is still rebuilding. re-check $URL in a minute with Cmd+Shift+R."
  exit 0
fi

# the page can match while an image it needs failed to push, which shows up
# as a broken picture, not an error. check every asset the page actually uses.
echo "page matches. checking every file it needs..."
BROKEN=0
for ASSET in $(git ls-files | grep -Ev '^(deploy\.sh|README\.md)$' | grep -v '^index\.html$'); do
  LOCAL=$(shasum -a 1 "$ASSET" | cut -c1-12)
  REMOTE=$(curl -s -H "Cache-Control: no-cache" "$URL$ASSET?cb=$$" | shasum -a 1 | cut -c1-12)
  if [ "$LOCAL" = "$REMOTE" ]; then
    printf "  ok       %s\n" "$ASSET"
  else
    printf "  MISSING  %s\n" "$ASSET"
    BROKEN=1
  fi
done

echo
if [ "$BROKEN" = "1" ]; then
  echo "the page is live but a file above did not make it. re-run this script."
  exit 1
fi
echo "LIVE, page and every file it needs - $URL"
echo
echo "your browser will still show the old copy for up to 10 minutes."
echo "hard-reload with Cmd+Shift+R, or open $URL?v=$STAMP"
