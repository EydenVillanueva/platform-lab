#!/usr/bin/env bash
# L01 · checks app/Dockerfile and the image it produces.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need docker curl jq

DF="$ROOT/app/Dockerfile"
DI="$ROOT/app/.dockerignore"
TAG="launchpad-api:l01-check"
PORT=18080

title "Static checks"
if [ -f "$DF" ]; then pass "app/Dockerfile exists"; else fail "app/Dockerfile not found"; summary; fi

if [ -f "$DI" ] && grep -q 'node_modules' "$DI"; then
  pass ".dockerignore excludes node_modules"
else
  fail ".dockerignore must exist and exclude node_modules" "otherwise your Mac's node_modules is copied into a Linux image"
fi

stages="$(grep -ciE '^[[:space:]]*FROM[[:space:]]' "$DF")"
if [ "$stages" -ge 2 ]; then pass "multi-stage build ($stages FROM lines)"; else fail "use a multi-stage build (two or more FROM lines)"; fi

# Base images without a tag or digest (stage names like "FROM deps" are fine).
untagged="$(awk '
  tolower($1) == "from" {
    img = $2; if (img ~ /^--/) img = $3
    for (i = 1; i < NF; i++) if (tolower($i) == "as") stages[tolower($(i + 1))] = 1
    if (img !~ /[:@]/ && !(tolower(img) in stages) && img != "scratch") print img
  }' "$DF")"
if grep -qiE '^[[:space:]]*FROM[[:space:]]+[^[:space:]]+:latest' "$DF"; then
  fail "do not use :latest in FROM; pin a version such as node:22-alpine"
elif [ -n "$untagged" ]; then
  fail "base image without a version: $untagged" "add a tag, for example node:22-alpine"
else
  pass "base images are pinned"
fi

if grep -qiE 'npm[[:space:]]+(ci|clean-install)' "$DF"; then pass "installs with npm ci"; else fail "install with npm ci" "npm ci installs exactly what package-lock.json says"; fi

if grep -qiE -- '--omit=dev|--omit[[:space:]]+dev|--only=prod|--production' "$DF"; then
  pass "production install omits devDependencies"
else
  fail "the image must not contain devDependencies such as nodemon" "npm ci --omit=dev"
fi

if grep -qiE '^[[:space:]]*USER[[:space:]]+' "$DF"; then pass "sets a USER"; else fail "run as a non-root USER"; fi

if grep -qiE '^[[:space:]]*CMD[[:space:]]*\[[[:space:]]*"node"' "$DF"; then
  pass 'starts with CMD ["node", ...] (exec form)'
else
  fail 'use CMD ["node", "src/server.js"]' "exec form makes node PID 1 so it gets SIGTERM; 'npm start' and shell form get in the way"
fi

if grep -qiE '^[[:space:]]*ARG[[:space:]]+APP_VERSION' "$DF"; then pass "accepts the APP_VERSION build argument"; else fail "add ARG APP_VERSION (and ENV APP_VERSION=\$APP_VERSION)"; fi

if have hadolint; then
  if out="$(hadolint "$DF" 2>&1)"; then pass "hadolint: no findings"; else warn "hadolint findings (read them, fix what you agree with):"; printf '%s\n' "$out" | sed 's/^/        /'; fi
else
  warn "hadolint not installed, lint skipped"
fi

title "Build"
if docker build -q -t "$TAG" --build-arg APP_VERSION=l01-check --build-arg GIT_SHA=abc1234 "$ROOT/app" >/dev/null; then
  pass "image builds"
else
  fail "docker build failed" "run it yourself to see the error: docker build -t launchpad-api:dev app/"
  summary
fi

bytes="$(docker image inspect -f '{{.Size}}' "$TAG")"
mb=$((bytes / 1024 / 1024))
if [ "$mb" -le 250 ]; then pass "image size is ${mb} MB (limit 250)"; else fail "image is ${mb} MB, aim for under 250" "small base image, production deps only, a .dockerignore"; fi

user="$(docker image inspect -f '{{.Config.User}}' "$TAG")"
case "$user" in
  "" | root | 0 | 0:0) fail "image runs as root (USER='$user')" ;;
  *) pass "image runs as user '$user'" ;;
esac

title "Run"
cid="$(docker run -d -p "$PORT:8080" "$TAG")"
ready=0
for _ in $(seq 1 20); do
  if curl -fs --max-time 1 "http://127.0.0.1:$PORT/readyz" >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
if [ "$ready" -eq 1 ]; then
  pass "/readyz answers 200"
else
  fail "the container never became ready" "docker logs $cid"
  docker logs "$cid" 2>&1 | tail -5 | sed 's/^/        /'
fi

version="$(curl -fs --max-time 2 "http://127.0.0.1:$PORT/version" | jq -r '.version' 2>/dev/null || true)"
if [ "$version" = "l01-check" ]; then pass "/version reports the build argument"; else fail "/version reported '$version', expected 'l01-check'" "ARG APP_VERSION then ENV APP_VERSION=\$APP_VERSION in the runtime stage"; fi

start="$(date +%s)"
docker stop -t 10 "$cid" >/dev/null
end="$(date +%s)"
secs=$((end - start))
code="$(docker inspect -f '{{.State.ExitCode}}' "$cid")"
if [ "$code" = "0" ] && [ "$secs" -le 5 ]; then
  pass "graceful shutdown: exit code 0 after ${secs}s"
else
  fail "shutdown was not graceful: exit code $code after ${secs}s" "137 after ~10s means SIGKILL: node did not receive SIGTERM. Is CMD in exec form?"
fi
docker rm "$cid" >/dev/null 2>&1 || true

summary
