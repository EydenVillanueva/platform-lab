#!/usr/bin/env bash
# L05 · checks .github/workflows/ci.yml locally and, if gh is available, the last run on main.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"

WF="$ROOT/.github/workflows/ci.yml"

title "Workflow file"
if [ -f "$WF" ]; then pass ".github/workflows/ci.yml exists"; else fail ".github/workflows/ci.yml not found"; summary; fi

if have actionlint; then
  if out="$(cd "$ROOT" && actionlint .github/workflows/ci.yml 2>&1)"; then pass "actionlint: no findings"; else fail "actionlint found problems"; printf '%s\n' "$out" | sed 's/^/        /'; fi
else
  warn "actionlint not installed, syntax check skipped"
fi

has() { grep -qE "$1" "$WF"; }
if has 'pull_request'; then pass "runs on pull requests"; else fail "add the pull_request trigger"; fi
if has 'push:' && has 'main'; then pass "runs on pushes to main"; else fail "add a push trigger for main"; fi
if has 'npm (ci|clean-install)' && has 'npm (test|run test)'; then pass "installs with npm ci and runs the tests"; else fail "run npm ci and npm test"; fi
if has 'working-directory:[[:space:]]*\.?/?app' || has 'cd app'; then pass "runs the Node steps inside app/"; else fail "the package.json is in app/: use working-directory: app"; fi
if has 'needs:'; then pass "the image job depends on the tests (needs)"; else fail "the image job must need the test job"; fi
if has "github\\.ref[[:space:]]*==[[:space:]]*'refs/heads/main'" || has 'github\.event_name[[:space:]]*==[[:space:]]*.push.'; then
  pass "the image is only pushed from main"
else
  fail "add an if: condition so the image job only runs on pushes to main"
fi
if has 'packages:[[:space:]]*write'; then pass "permissions include packages: write"; else fail "the image job needs permissions: packages: write"; fi
if has 'ghcr\.io'; then pass "pushes to ghcr.io"; else fail "push the image to ghcr.io"; fi
if has 'github\.sha'; then pass "tags the image with the commit SHA"; else fail "tag the image with \${{ github.sha }}"; fi
if has 'APP_VERSION'; then pass "passes APP_VERSION as a build argument"; else warn "pass APP_VERSION (and GIT_SHA) as build arguments"; fi
if has 'type=gha'; then pass "uses the GitHub Actions cache for layers"; else warn "add cache-from/cache-to type=gha to speed up builds"; fi
if has 'ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}'; then fail "a token or access key is written in the workflow: remove it and rotate it"; else pass "no hard-coded credentials"; fi

title "Latest run on GitHub"
if have gh && (cd "$ROOT" && gh repo view >/dev/null 2>&1); then
  run="$(cd "$ROOT" && gh run list --workflow ci.yml --branch main --limit 1 --json conclusion,headSha,status 2>/dev/null || true)"
  conclusion="$(printf '%s' "$run" | jq -r '.[0].conclusion // empty' 2>/dev/null)"
  sha="$(printf '%s' "$run" | jq -r '.[0].headSha // empty' 2>/dev/null)"
  if [ "$conclusion" = "success" ]; then pass "last run on main succeeded (${sha:0:7})"; elif [ -n "$conclusion" ]; then fail "last run on main: $conclusion" "gh run view --log-failed"; else warn "no finished run on main yet (status: $(printf '%s' "$run" | jq -r '.[0].status // "none"'))"; fi
else
  warn "gh not available or this folder is not a GitHub repo yet: remote check skipped"
fi

title "The cluster runs the CI image"
if have kubectl && [ "$(kubectl config current-context 2>/dev/null)" = "kind-$CLUSTER" ]; then
  img="$(kget -n "$NS" get deployment launchpad-api -o jsonpath='{.spec.template.spec.containers[0].image}')"
  case "$img" in
    ghcr.io/*) pass "deployment runs $img" ;;
    *) warn "deployment runs '$img'; the milestone is to run the image CI built (README step 5)" ;;
  esac
  if grep -q 'ghcr.io/' "$ROOT/k8s/deployment.yaml" 2>/dev/null; then pass "k8s/deployment.yaml points to the GHCR image"; else warn "update k8s/deployment.yaml so git matches the cluster"; fi
else
  warn "kind cluster not selected: cluster check skipped"
fi

summary
