# L00 · Setup (30–45 min, once)

**Goal:** every tool installed, a 3-node Kubernetes cluster running on your Mac, and a GitHub repository for this lab.

## 1. Install the tools (macOS, Homebrew)

```bash
brew install --cask docker            # Docker Desktop. Open it once so the daemon starts.
brew install kind kubectl helm jq gh awscli
brew install hashicorp/tap/terraform  # or: brew install opentofu  (then: export TF=tofu)
brew install hadolint kubeconform actionlint shellcheck   # optional linters, checks get stricter
```

Docker Desktop → Settings → Resources: give it **at least 4 CPUs and 6 GB of memory**. kind runs three Kubernetes nodes as containers inside Docker.

You also need **Node 22** (`node -v`). Use the version manager you already have.

## 2. Check

```bash
scripts/doctor.sh
```

Everything under "Required for week 1" must pass. Week 2 items can wait until Saturday.

## 3. Create the cluster

```bash
scripts/cluster-up.sh
kubectl get nodes          # three nodes, all Ready (the first run downloads an image, ~1–2 min)
```

`scripts/cluster-down.sh` deletes it. You can recreate it any time: your YAML files stay in `k8s/`.

## 4. Make this folder a GitHub repository

The CI lab (L05) needs it. Keep `solutions.zip` **out** of the repository (it is already in `.gitignore`).

```bash
git init && git add . && git commit -m "Platform lab: starting point"
gh repo create platform-lab --private --source . --push
```

## 5. AWS safety first (do it now, it takes 3 minutes)

Week 2 creates real resources in your personal AWS account. Before that:

1. AWS Console → **Billing → Budgets → Create budget → Zero spend budget** (or a $5 monthly budget) with your email. You get an email the moment anything costs money.
2. Configure the CLI with a profile you control: `aws configure sso` or `aws configure`, then `aws sts get-caller-identity`.

The cost rules for every AWS lab are in the root `README.md`.

**Done when:** `scripts/doctor.sh` shows no FAIL in week 1, and `kubectl get nodes` shows three Ready nodes.
