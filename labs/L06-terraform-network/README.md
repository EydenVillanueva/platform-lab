# L06 · Terraform by hand: a VPC and a container registry

**Read first:** Guide chapter 6 (AWS networking) and chapter 7 (Terraform).
**You write:** `infra/network.tf`, `infra/ecr.tf`, `infra/outputs.tf` (and any variables you need).
**Rule for this lab:** write every line yourself. No AI, no copy-paste from the web; the Terraform registry docs are allowed. The goal is to be able to explain each block.

## Cost: create and destroy on the same day

Everything in this lab is free or costs cents: a VPC, subnets, route tables, an internet gateway, an S3 gateway endpoint and an ECR repository with a few small images. **Do not add a NAT gateway**: it is billed by the hour and the cost guard will reject it. Destroy everything before you stop for the day.

## Tasks

1. **Network** (`network.tf`):
   - VPC `10.20.0.0/16` with DNS support and DNS hostnames enabled, tag `Name = "platform-lab"`.
   - Two availability zones (use the `aws_availability_zones` data source, do not hard-code them).
   - Two **public** subnets (`10.20.0.0/24`, `10.20.1.0/24`) with `map_public_ip_on_launch = true` and the tag `kubernetes.io/role/elb = "1"`.
   - Two **private** subnets (`10.20.10.0/24`, `10.20.11.0/24`) with the tag `kubernetes.io/role/internal-elb = "1"`.
   - Create the subnets with **`for_each`** over a map, not four copies of the same block.
   - An internet gateway, a public route table with `0.0.0.0/0 → internet gateway`, associated with both public subnets.
   - A private route table **without** a default route, associated with both private subnets. Add a comment explaining what you would add in production and why it costs money.
   - An **S3 gateway endpoint** attached to the private route table (free; private subnets reach S3 without a NAT).
2. **Registry** (`ecr.tf`): repository `launchpad-api` with immutable tags, scan on push, `force_delete = true` (lab only: it lets `destroy` remove a repository that still has images), and a lifecycle policy that keeps the last 10 images.
3. **Outputs** (`outputs.tf`): `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `ecr_repository_url`.
4. Plan through the cost guard, apply, look, destroy:

```bash
terraform -chdir=infra fmt -recursive
scripts/tf-guard.sh                      # init + plan + cost guard
(cd infra && terraform apply tfplan)
terraform -chdir=infra output
aws ec2 describe-subnets --filters Name=tag:Project,Values=platform-lab \
  --query 'Subnets[].[CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table
labs/L06-terraform-network/check.sh      # run it while the infrastructure exists
terraform -chdir=infra destroy
scripts/aws-leftovers.sh
```

5. **Read a dangerous plan.** Before destroying, change the CIDR of one public subnet and run `scripts/tf-guard.sh` again. Find the line that says the subnet *must be replaced*. Why can't AWS change it in place? Revert the change.

## Done when

`labs/L06-terraform-network/check.sh` passes **while the infrastructure exists**, and `scripts/aws-leftovers.sh` is clean after the destroy.

## Stretch

- Move the state to an S3 backend with `use_lockfile = true` (see the comment in `versions.tf`). What problem does the lock solve when two people run `apply`?
- Turn the network into a local module `infra/modules/network` with inputs and outputs.

## Say it out loud

> "Public subnets have a route to an internet gateway; private subnets don't. Workloads live in private subnets and reach the internet through a NAT gateway, one per AZ in production, which is a real cost line, so for S3 and DynamoDB I add gateway endpoints, which are free. I tag the subnets so the AWS Load Balancer Controller knows where to put public and internal load balancers."
