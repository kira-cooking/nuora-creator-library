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
echo "waiting for it to go live..."
for i in $(seq 1 30); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo 000)
  if [ "$CODE" = "200" ]; then
    echo "LIVE - $URL"
    echo "open it in a private/incognito window to confirm it needs no login."
    exit 0
  fi
  sleep 10
done
echo "still building. check $URL in a minute."
