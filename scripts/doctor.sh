#!/usr/bin/env bash
# Checks that every tool the labs use is installed. Safe to run any time.
. "$(dirname "$0")/lib.sh"

title "Required for week 1"
ver() {
  case "$1" in
    kubectl) kubectl version --client 2>/dev/null | head -1 ;;
    helm) helm version --short 2>/dev/null ;;
    terraform) terraform version 2>/dev/null | head -1 ;;
    tofu) tofu version 2>/dev/null | head -1 ;;
    *) "$1" --version 2>/dev/null | head -1 ;;
  esac
}
for c in git node npm docker kind kubectl jq curl; do
  if have "$c"; then pass "$c  ($(ver "$c"))"; else fail "$c is missing" "see labs/L00-setup/README.md"; fi
done
if have node; then
  major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$major" -ge 20 ]; then pass "node version $major is 20 or newer"; else fail "node $major is too old" "install Node 22 LTS"; fi
fi
if have docker && docker info >/dev/null 2>&1; then pass "docker daemon is running"; else fail "docker daemon is not running" "start Docker Desktop"; fi
if have gh; then pass "gh  ($(gh --version | head -1))"; else warn "gh (GitHub CLI) is missing: optional, but L05 uses it to read CI results"; fi

title "Required for week 2"
if have terraform; then pass "terraform  ($(ver terraform))"; elif have tofu; then pass "tofu  ($(ver tofu))  (OpenTofu works too: export TF=tofu)"; else fail "terraform is missing" "brew install hashicorp/tap/terraform"; fi
for c in aws helm; do
  if have "$c"; then pass "$c  ($(ver "$c"))"; else fail "$c is missing" "see labs/L00-setup/README.md"; fi
done
if have aws && aws sts get-caller-identity >/dev/null 2>&1; then pass "AWS credentials work (aws sts get-caller-identity)"; else warn "AWS credentials not configured yet (needed from L06)"; fi

title "Optional linters (checks get stricter when present)"
for c in hadolint kubeconform actionlint shellcheck; do
  if have "$c"; then pass "$c"; else warn "$c not installed (brew install $c)"; fi
done

summary
