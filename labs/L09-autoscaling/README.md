# L09 · Horizontal Pod Autoscaler under load

**Read first:** Guide 3.6 (scaling).
**You write:** `chart/launchpad/templates/hpa.yaml` and an `autoscaling` section in `values.yaml`.

## Why interviewers care

*"Traffic triples at 9 am. What scales, based on what, and how fast?"* You need the chain: metrics-server → HPA → more pods → (on EKS) a node autoscaler such as Karpenter adds nodes when pods are Pending.

## Tasks

1. Install metrics-server in the kind cluster (the script adds the flag kind needs):

```bash
scripts/install-metrics-server.sh
kubectl top nodes            # may take a minute before numbers appear
```

2. In the chart, add:
   - `autoscaling.enabled` (default `false`), `minReplicas: 2`, `maxReplicas: 6`, `targetCPUUtilizationPercentage: 60`.
   - `templates/hpa.yaml` (API `autoscaling/v2`) rendered only when enabled.
   - In the Deployment template: **do not render `replicas` when autoscaling is enabled**. (Why? What would happen on every `helm upgrade` otherwise?)
3. Enable it for dev and generate load:

```bash
helm upgrade launchpad chart/launchpad -n launchpad-helm -f chart/launchpad/values-dev.yaml --set autoscaling.enabled=true
scripts/load.sh 180                       # 3 minutes of CPU-heavy requests from inside the cluster
kubectl -n launchpad-helm get hpa -w      # other terminal: watch TARGETS and REPLICAS
```

4. Stop the load and keep watching. Scale-down is slower than scale-up on purpose (about 5 minutes by default). Why is that a good default?

## Done when

`labs/L09-autoscaling/check.sh` passes (it needs the HPA to have scaled at least once).

## Say it out loud

> "The HPA compares average CPU usage against the pods' CPU requests, so requests have to be realistic or the HPA reacts to the wrong number. It scales the pods; when pods don't fit, a node autoscaler like Karpenter adds nodes. For spiky, predictable events I'd raise minReplicas ahead of time, because reactive scaling always lags."
