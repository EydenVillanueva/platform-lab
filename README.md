# platform-lab

A hands-on lab for the Senior/Staff Platform Engineer interviews: a small Node.js service (already written) that you containerize, run on Kubernetes, ship with CI, provision with Terraform, package with Helm and autoscale. Everything you build here becomes the project you describe in the interview.

**Start here:** `PLAN.md` (what to do each day) → `labs/L00-setup/README.md`.

## Map

| Path | What it is | Who writes it |
|---|---|---|
| `app/` | `launchpad-api`, the service. Tests: `cd app && npm ci && npm test`. | given (do not change) |
| `labs/Lxx-*/README.md` | Each lab: goal, why interviewers care, tasks, "say it out loud". | given |
| `labs/Lxx-*/check.sh` | Runs in seconds and tells you what passes and what to fix. | given |
| `HINTS.md` | Two hints per lab: a push, then the shape. No solutions. | given |
| `drills/` | Seven broken workloads to debug (after L04). | given |
| `app/Dockerfile`, `k8s/`, `.github/workflows/`, `infra/*.tf`, `chart/` | The lab work. | **you** |
| `tools/create-service/src/generate.js` | Stretch: golden-path generator (L10). | **you** |
| `scripts/` | Cluster up/down, image loading, cost guard, leftovers, milestone checks. | given |
| `solutions.zip` | Reference solutions and drill answers. Open a lab's solution only after its check passes, then compare. | given |

## How to work a lab

1. Read the Guide section it names (printed).
2. Read the lab README. Write the files.
3. Run its `check.sh`. Fix until it passes. Stuck for 10 minutes? Ask your mentor for `Hint 1 — Lxx`, or read `HINTS.md`.
4. Do the "Say it out loud" part. It is what turns a passing check into an interview answer.
5. Write anything that surprised you in `NOTES.md`: it becomes your review material.

## AWS cost rules (week 2)

You use your personal AWS account. The labs are designed to cost cents.

1. **Set a budget alert before L06** (L00 step 5).
2. **Apply only plans that passed `scripts/tf-guard.sh`.** It rejects NAT gateways, Elastic IPs, EKS clusters, EC2 instances, load balancers, databases and interface endpoints: everything billed by the hour.
3. **Destroy the same day:** `terraform -chdir=infra destroy`, then `scripts/aws-leftovers.sh`.
4. **No EKS in this lab.** A cluster costs $0.10 per hour for the control plane alone, before any node. kind gives you the same Kubernetes API for free; the Guide covers what is different on EKS.

## Requirements

macOS with Docker Desktop (4 CPUs, 6 GB), Node 22, kind, kubectl, jq, git and the GitHub CLI for week 1; Terraform (or OpenTofu with `export TF=tofu`), the AWS CLI and Helm for week 2. `scripts/doctor.sh` checks all of it.

## A note on the checks

The check scripts were written for the bash that ships with macOS. The static parts were tested; the parts that talk to your cluster, GitHub and AWS could not be run where they were written. If a check reports something that looks wrong, say `Review — check Lxx` to your mentor with the output.
