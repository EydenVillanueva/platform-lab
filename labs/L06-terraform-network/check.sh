#!/usr/bin/env bash
# L06 · checks infra/ for the network and the ECR repository.
# shellcheck disable=SC2015  # pass() always succeeds, so "A && pass || fail" is safe here
# Uses the applied state if there is one, otherwise a fresh plan (needs AWS credentials).
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
TF="${TF:-terraform}"
need "$TF" jq
I="$ROOT/infra"

title "Files and formatting"
for f in network.tf ecr.tf outputs.tf; do
  if [ -f "$I/$f" ]; then pass "infra/$f exists"; else fail "infra/$f not found"; fi
done
if "$TF" -chdir="$I" fmt -check -recursive >/dev/null 2>&1; then pass "terraform fmt: formatted"; else fail "files are not formatted" "$TF -chdir=infra fmt -recursive"; fi
if "$TF" -chdir="$I" init -input=false >/dev/null 2>&1 && "$TF" -chdir="$I" validate >/dev/null 2>&1; then
  pass "terraform validate"
else
  fail "terraform validate failed"; "$TF" -chdir="$I" validate 2>&1 | sed 's/^/        /' | head -20; summary
fi
if grep -q 'for_each' "$I/network.tf" 2>/dev/null; then pass "subnets use for_each"; else fail "create the subnets with for_each over a map"; fi
if grep -q 'aws_nat_gateway' "$I"/*.tf; then fail "a NAT gateway is declared: remove it (hourly cost)"; else pass "no NAT gateway declared"; fi

title "What Terraform manages"
if (cd "$I" && "$TF" state list 2>/dev/null | grep -q .); then
  src="applied state"
  json="$(cd "$I" && "$TF" show -json 2>/dev/null)"
  jroot='.values'
else
  src="plan (nothing applied yet)"
  if ! (cd "$I" && "$TF" plan -input=false -out=tfplan >/dev/null 2>&1); then
    fail "could not plan: are your AWS credentials configured? (aws sts get-caller-identity)"; summary
  fi
  json="$(cd "$I" && "$TF" show -json tfplan 2>/dev/null)"
  jroot='.planned_values'
fi
info "reading the $src"
res() { printf '%s' "$json" | jq -c "[$jroot | .. | objects | select(has(\"type\") and has(\"values\"))] | map(select(.type == \"$1\"))"; }
count() { res "$1" | jq 'length'; }

[ "$(count aws_vpc)" = "1" ] && pass "one VPC" || fail "expected exactly one aws_vpc"
cidr="$(res aws_vpc | jq -r '.[0].values.cidr_block // empty')"
[ "$cidr" = "10.20.0.0/16" ] && pass "VPC CIDR 10.20.0.0/16" || fail "VPC CIDR is '$cidr', expected 10.20.0.0/16"
[ "$(res aws_vpc | jq -r '.[0].values.enable_dns_hostnames')" = "true" ] && pass "DNS hostnames enabled" || fail "enable_dns_hostnames must be true"

subnets="$(res aws_subnet)"
n="$(printf '%s' "$subnets" | jq 'length')"
pub="$(printf '%s' "$subnets" | jq '[.[] | select(.values.tags["kubernetes.io/role/elb"] == "1" and .values.map_public_ip_on_launch == true)] | length')"
priv="$(printf '%s' "$subnets" | jq '[.[] | select(.values.tags["kubernetes.io/role/internal-elb"] == "1" and (.values.map_public_ip_on_launch | not))] | length')"
azs="$(printf '%s' "$subnets" | jq '[.[].values.availability_zone] | unique | length')"
[ "$n" = "4" ] && pass "four subnets" || fail "found $n subnets, expected 4"
[ "$pub" = "2" ] && pass "two public subnets (public IPs + elb tag)" || fail "$pub subnets look public, expected 2" "map_public_ip_on_launch = true and tag kubernetes.io/role/elb = \"1\""
[ "$priv" = "2" ] && pass "two private subnets (internal-elb tag)" || fail "$priv subnets look private, expected 2"
if [ "$src" = "applied state" ]; then
  [ "$azs" = "2" ] && pass "subnets span two availability zones" || fail "subnets are in $azs AZ(s), expected 2"
else
  info "availability zones are only known after apply"
fi
[ "$(count aws_internet_gateway)" = "1" ] && pass "internet gateway" || fail "expected one aws_internet_gateway"
[ "$(count aws_route_table)" -ge 2 ] && pass "public and private route tables" || fail "expected two aws_route_table"
[ "$(count aws_route_table_association)" = "4" ] && pass "four route table associations" || fail "expected four aws_route_table_association"
s3ep="$(res aws_vpc_endpoint | jq '[.[] | select((.values.service_name // "") | test("s3$"))] | length')"
[ "$s3ep" -ge 1 ] && pass "S3 gateway endpoint" || warn "no S3 gateway endpoint (free, and a good interview point)"

repo="$(res aws_ecr_repository)"
[ "$(printf '%s' "$repo" | jq 'length')" = "1" ] && pass "one ECR repository" || fail "expected one aws_ecr_repository"
[ "$(printf '%s' "$repo" | jq -r '.[0].values.name // empty')" = "launchpad-api" ] && pass "repository name launchpad-api" || fail "name the repository launchpad-api"
[ "$(printf '%s' "$repo" | jq -r '.[0].values.image_tag_mutability // empty')" = "IMMUTABLE" ] && pass "immutable tags" || fail "set image_tag_mutability = \"IMMUTABLE\""
[ "$(printf '%s' "$repo" | jq -r '.[0].values.image_scanning_configuration[0].scan_on_push // false')" = "true" ] && pass "scan on push" || fail "enable image_scanning_configuration { scan_on_push = true }"
[ "$(count aws_ecr_lifecycle_policy)" = "1" ] && pass "lifecycle policy" || fail "add an aws_ecr_lifecycle_policy that keeps the last 10 images"

title "Outputs"
for o in vpc_id public_subnet_ids private_subnet_ids ecr_repository_url; do
  if grep -qE "output[[:space:]]+\"$o\"" "$I/outputs.tf" 2>/dev/null; then pass "output $o"; else fail "missing output $o"; fi
done

if [ "$src" = "applied state" ]; then
  printf '\n  Reminder: destroy before you stop for the day:  %s -chdir=infra destroy && scripts/aws-leftovers.sh\n' "$TF"
fi
rm -f "$I/tfplan"
summary
