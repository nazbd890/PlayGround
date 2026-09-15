#!/usr/bin/env bash
# Startup for the PlayGround Dodger static game.
# Fresh-runner safe: zero npm dependencies, Node stdlib only (python3 fallback).
# Serves ./index.html (or ./dist/index.html when present) on ${PORT:-3000} in the foreground.
set -euo pipefail

# 1. Locate project root (directory containing this script).
if command -v /usr/bin/time >/dev/null 2>&1; then TIME_P="/usr/bin/time -p"; else TIME_P=""; fi
$TIME_P true 2>/dev/null || true
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
$TIME_P cd "$SCRIPT_DIR"

# 2. Resolve port (workflow passes PORT=3000).
PORT="${PORT:-3000}"
export PORT
$TIME_P bash -c "echo \"PORT=$PORT\""

# 3. Confirm a playable HTML entrypoint exists before starting the server.
if [ -f ./index.html ]; then
  $TIME_P test -s ./index.html
  ENTRYPOINT="./index.html"
elif [ -f ./dist/index.html ]; then
  $TIME_P test -s ./dist/index.html
  ENTRYPOINT="./dist/index.html"
else
  echo "ERROR: neither ./index.html nor ./dist/index.html exists" >&2
  exit 1
fi
$TIME_P bash -c "echo \"ENTRYPOINT=$ENTRYPOINT\""

# 4. Fresh-runner dependency check: node preferred (verified working server path).
if command -v node >/dev/null 2>&1; then
  $TIME_P command -v node
  $TIME_P node --version
  HAVE_NODE=1
else
  $TIME_P bash -c "echo 'node not found, will try python3 fallback'"
  HAVE_NODE=0
fi

# 5. Optional npm reuse: only when a project package.json exists (this static game has none).
if [ -f ./package.json ]; then
  $TIME_P command -v npm
  if [ ! -d ./node_modules ]; then
    $TIME_P npm install
  else
    $TIME_P bash -c "echo 'node_modules present, reusing dependencies'"
  fi
else
  $TIME_P bash -c "echo 'no package.json, skipping npm install'"
fi

# 6. Optional build reuse: only when a build script exists.
if [ -f ./package.json ] && $TIME_P npm run --silent build --if-present; then
  $TIME_P bash -c "echo 'build step done (or no build script)'"
else
  $TIME_P bash -c "echo 'no build required'"
fi

# 7. Serve in the foreground so the workflow/tmux session stays attached.
# Tunnel setup stays in the workflow, not here.
$TIME_P bash -c "echo 'starting static server on 0.0.0.0:'$PORT"
if [ "$HAVE_NODE" = 1 ]; then
  $TIME_P test -s ./server.mjs
  exec node ./server.mjs
else
  $TIME_P command -v python3
  exec python3 -m http.server "$PORT" --bind 0.0.0.0
fi
