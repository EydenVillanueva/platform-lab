#!/usr/bin/env bash
# Cost guard (policy as code, in miniature): plans infra/ and refuses the plan if it would
# create something that is billed by the hour. Apply only a plan that passed this guard.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
TF="${TF:-terraform}"
cd "$ROOT/infra"

"$TF" init -input=false >/dev/null
"$TF" plan -input=false -out=tfplan
"$TF" show -json tfplan > plan.json

blocked="$(jq -r '
  .resource_changes[]?
  | select(.change.actions | index("create"))
  | select(
      (.type | IN("aws_nat_gateway", "aws_eip", "aws_eks_cluster", "aws_eks_node_group",
                  "aws_instance", "aws_autoscaling_group", "aws_lb", "aws_alb",
                  "aws_db_instance", "aws_rds_cluster", "aws_elasticache_cluster",
                  "aws_elasticache_replication_group", "aws_ec2_transit_gateway"))
      or (.type == "aws_vpc_endpoint" and .change.after.vpc_endpoint_type == "Interface")
    )
  | "  - \(.address)  (\(.type))"' plan.json)"

echo
if [ -n "$blocked" ]; then
  printf '%sCOST GUARD: this plan creates resources billed by the hour:%s\n%s\n' "$R" "$N" "$blocked"
  echo "Remove them (see the cost rules in README.md). The plan file was deleted."
  rm -f tfplan
  exit 1
fi
printf '%sCost guard passed.%s Apply exactly this plan with:  (cd infra && %s apply tfplan)\n' "$G" "$N" "$TF"
