# L08 · Package the service as a Helm chart

**Read first:** Guide 4.1–4.3 (Helm).
**You write:** `chart/launchpad/` (create it with `helm create chart/launchpad`, then delete what you do not need).

## Why interviewers care

A platform team rarely hands developers raw YAML. It hands them a chart (or a template) with sensible defaults, and each environment overrides a few values. Expect: *How do you manage per-environment configuration? How do you roll back a bad release? How does a ConfigMap change restart the pods?*

## Tasks

1. `helm create chart/launchpad`, then keep only `Chart.yaml`, `values.yaml`, `templates/_helpers.tpl`, `templates/deployment.yaml`, `templates/service.yaml`, `templates/NOTES.txt`, and add `templates/configmap.yaml`. Delete the rest (ingress, serviceaccount, hpa, tests) for now.
2. Make the chart produce what you wrote by hand in L02–L04:
   - All resource names come from the release name, so with `helm install launchpad …` the Deployment and Service are both called **`launchpad`**.
   - `values.yaml`: `replicaCount`, `image.repository`, `image.tag`, `image.pullPolicy`, `service.port: 80`, `containerPort: 8080`, `resources`, `config` (a map rendered into the ConfigMap), `existingSecret` (the name of a Secret with `API_KEY`).
   - Probes (`/readyz`, `/healthz`) and the rolling update strategy from L04.
   - A `checksum/config` annotation on the pod template computed from the ConfigMap, so changing a config value rolls the pods automatically.
3. Two environment files:
   - `values-dev.yaml`: 1 replica, `config.APP_ENV: dev`.
   - `values-prod.yaml`: 3 replicas, `config.APP_ENV: prod`, larger requests.
4. Render before installing (this is how you review a chart change):

```bash
helm lint chart/launchpad
helm template launchpad chart/launchpad -f chart/launchpad/values-dev.yaml | less
helm template launchpad chart/launchpad -f chart/launchpad/values-prod.yaml | grep replicas
```

5. Install the dev release in its own namespace, change something, roll back:

```bash
kubectl create namespace launchpad-helm
kubectl -n launchpad-helm create secret generic launchpad-secret --from-literal=API_KEY=change-me-123
helm upgrade --install launchpad chart/launchpad -n launchpad-helm -f chart/launchpad/values-dev.yaml
helm upgrade launchpad chart/launchpad -n launchpad-helm -f chart/launchpad/values-dev.yaml --set config.GREETING="v2 greeting"
kubectl -n launchpad-helm get pods -w        # the checksum annotation restarts them
helm history launchpad -n launchpad-helm
helm rollback launchpad 1 -n launchpad-helm
```

## Done when

`labs/L08-helm/check.sh` passes.

## Stretch

- Add an Ingress or, better, a Gateway API `HTTPRoute` template behind a `values` flag. (Guide 3.7 explains why Gateway API is where Kubernetes is heading.)

## Say it out loud

> "The chart is the contract between the platform and the service team: safe defaults in values.yaml, a small override file per environment, and helm template in CI so every change is reviewed as rendered YAML. A checksum annotation ties config changes to a rollout, and helm rollback returns to any previous release revision."
