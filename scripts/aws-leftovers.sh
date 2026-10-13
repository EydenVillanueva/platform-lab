#!/usr/bin/env bash
# Lists anything from this lab still alive in your AWS account. Run it after every destroy.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
need aws jq
TF="${TF:-terraform}"
REGION="${AWS_REGION:-us-east-1}"

title "Terraform state"
if [ -d "$ROOT/infra/.terraform" ] && (cd "$ROOT/infra" && "$TF" state list 2>/dev/null | grep -q .); then
  fail "infra/ state still has resources:"; (cd "$ROOT/infra" && "$TF" state list | sed 's/^/        /')
else
  pass "infra/ state is empty"
fi

title "Tagged resources (Project=platform-lab) in $REGION"
arns="$(aws resourcegroupstaggingapi get-resources --region "$REGION" --tag-filters Key=Project,Values=platform-lab \
  --query 'ResourceTagMappingList[].ResourceARN' --output text 2>/dev/null || true)"
if [ -z "$arns" ] || [ "$arns" = "None" ]; then pass "nothing tagged Project=platform-lab"; else warn "still listed (this index can lag a few minutes after a destroy):"; printf '%s\n' "$arns" | tr '\t' '\n' | sed 's/^/        /'; fi

title "Hourly-billed resources in $REGION (any tag)"
nat="$(aws ec2 describe-nat-gateways --region "$REGION" --filter Name=state,Values=available,pending --query 'length(NatGateways)' --output text 2>/dev/null || echo 0)"
if [ "$nat" = "0" ]; then pass "no NAT gateways"; else fail "$nat NAT gateway(s) running: about \$1 per day each"; fi
eks="$(aws eks list-clusters --region "$REGION" --query 'length(clusters)' --output text 2>/dev/null || echo 0)"
if [ "$eks" = "0" ]; then pass "no EKS clusters"; else fail "$eks EKS cluster(s): \$0.10 per hour each"; fi
eips="$(aws ec2 describe-addresses --region "$REGION" --query 'length(Addresses)' --output text 2>/dev/null || echo 0)"
if [ "$eips" = "0" ]; then pass "no Elastic IPs"; else warn "$eips Elastic IP(s): public IPv4 addresses are billed hourly"; fi

summary
