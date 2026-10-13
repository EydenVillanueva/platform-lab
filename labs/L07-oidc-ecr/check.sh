#!/usr/bin/env bash
# L07 · checks the OIDC trust, the CI job that pushes to ECR, and the image in ECR.
# shellcheck disable=SC2015  # pass() always succeeds, so "A && pass || fail" is safe here
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
TF="${TF:-terraform}"
need "$TF" jq
I="$ROOT/infra"
WF="$ROOT/.github/workflows/ci.yml"

title "Terraform"
if [ -f "$I/oidc.tf" ]; then pass "infra/oidc.tf exists"; else fail "infra/oidc.tf not found"; summary; fi
if grep -q 'token.actions.githubusercontent.com' "$I/oidc.tf"; then pass "references the GitHub OIDC provider"; else fail "the OIDC provider URL is missing"; fi
if grep -q 'aws_iam_policy_document' "$I/oidc.tf"; then pass "policies written with aws_iam_policy_document"; else warn "prefer data \"aws_iam_policy_document\" over inline JSON"; fi
if grep -qE 'AssumeRoleWithWebIdentity' "$I/oidc.tf"; then pass "trust allows sts:AssumeRoleWithWebIdentity"; else fail "the trust policy must allow sts:AssumeRoleWithWebIdentity"; fi
if grep -qE ':aud' "$I/oidc.tf" && grep -q 'sts.amazonaws.com' "$I/oidc.tf"; then pass "audience condition (aud = sts.amazonaws.com)"; else fail "add the :aud condition"; fi
if grep -qE ':sub' "$I/oidc.tf"; then pass "subject condition present"; else fail "add the :sub condition: without it ANY repository on GitHub could assume the role"; fi
if grep -qE 'repo:\*|repo:[^"]*/\*"' "$I/oidc.tf"; then fail "the sub condition uses a wildcard over repositories"; fi
if grep -q 'ecr:\*' "$I/oidc.tf"; then fail "ecr:* is too broad: list the push actions"; else pass "no ecr:* wildcard"; fi
grep -qE 'output[[:space:]]+"github_actions_role_arn"' "$I"/*.tf && pass "output github_actions_role_arn" || fail "add output \"github_actions_role_arn\""

title "Workflow"
if [ -f "$WF" ]; then
  grep -qE 'id-token:[[:space:]]*write' "$WF" && pass "permissions: id-token: write" || fail "the push-ecr job needs permissions: id-token: write"
  grep -q 'configure-aws-credentials' "$WF" && pass "uses aws-actions/configure-aws-credentials" || fail "use aws-actions/configure-aws-credentials"
  grep -q 'role-to-assume' "$WF" && pass "assumes a role (role-to-assume)" || fail "set role-to-assume"
  if grep -qiE 'aws-access-key-id|aws_secret_access_key|aws-secret-access-key' "$WF"; then fail "access keys found in the workflow: the point of OIDC is to have none"; else pass "no long-lived AWS keys"; fi
  grep -q 'amazon-ecr-login' "$WF" && pass "logs in to ECR" || fail "use aws-actions/amazon-ecr-login"
  if have actionlint; then (cd "$ROOT" && actionlint .github/workflows/ci.yml >/dev/null 2>&1) && pass "actionlint: no findings" || fail "actionlint found problems (run: actionlint)"; fi
else
  fail ".github/workflows/ci.yml not found"
fi

title "AWS (while the infrastructure exists)"
if have aws && aws sts get-caller-identity >/dev/null 2>&1; then
  REGION="${AWS_REGION:-us-east-1}"
  trust="$(aws iam get-role --role-name platform-lab-gha-ecr --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null || true)"
  if [ -n "$trust" ]; then
    pass "role platform-lab-gha-ecr exists"
    sub="$(printf '%s' "$trust" | jq -r '[.. | objects | to_entries[] | select(.key == "token.actions.githubusercontent.com:sub") | .value] | flatten | join(", ")')"
    info "trusted subject: $sub"
    case "$sub" in *ref:refs/heads/main*) pass "only the main branch can assume it" ;; *) warn "the subject is not pinned to refs/heads/main" ;; esac
  else
    fail "role platform-lab-gha-ecr not found (applied? destroyed already?)"
  fi
  sha="$(cd "$ROOT" && git rev-parse origin/main 2>/dev/null || git rev-parse HEAD 2>/dev/null || true)"
  tags="$(aws ecr describe-images --region "$REGION" --repository-name launchpad-api --query 'imageDetails[].imageTags[]' --output text 2>/dev/null || true)"
  if [ -n "$sha" ] && printf '%s' "$tags" | tr '\t' '\n' | grep -qx "$sha"; then
    pass "ECR has launchpad-api:${sha:0:7} (your last commit on main)"
  elif [ -n "$tags" ]; then
    warn "ECR has images ($tags) but not the last main commit ${sha:0:7}"
  else
    fail "no images in ECR repository launchpad-api" "push to main and check the push-ecr job"
  fi
  printf '\n  Reminder: destroy when you are done:  %s -chdir=infra destroy && scripts/aws-leftovers.sh\n' "$TF"
else
  warn "AWS credentials not available: live checks skipped"
fi

summary
