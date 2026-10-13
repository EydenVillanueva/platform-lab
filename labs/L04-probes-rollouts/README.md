# L04 · Probes, resources, rolling updates and rollback

**Read first:** Guide 3.2–3.5 (probes, resources, rollouts, graceful shutdown).
**You write:** changes to `k8s/deployment.yaml`.

## Why interviewers care

This is where "I deployed it" becomes "I can run it in production". Expect: *What is the difference between liveness and readiness? What happens when a pod exceeds its memory limit? How do you deploy without downtime? How do you roll back?*

## Tasks

1. **Slow start on purpose.** Add the env var `STARTUP_DELAY_MS: "5000"`. The app now takes 5 seconds before `/readyz` answers 200 (`/healthz` answers immediately).
2. **Probes:**
   - `readinessProbe` → `GET /readyz` on 8080, every 5 s.
   - `livenessProbe` → `GET /healthz` on 8080, every 10 s.
   - `startupProbe` → `GET /healthz`, enough `failureThreshold × periodSeconds` for a slow start.
3. **Resources:** requests `cpu: 100m`, `memory: 128Mi`; limit `memory: 256Mi`. (Decide whether to set a CPU limit; be ready to defend the choice.)
4. **Rolling update strategy:** `maxUnavailable: 0`, `maxSurge: 1`.
5. **Graceful shutdown:** add a `preStop` hook that waits 5 seconds (`lifecycle.preStop.sleep.seconds: 5`, supported natively in recent Kubernetes versions) and keep `terminationGracePeriodSeconds` above that plus the app's own shutdown time.
6. **Roll out a new version and roll back:**

```bash
kubectl apply -f k8s/
scripts/load-image.sh v2                                   # builds and loads launchpad-api:v2
kubectl -n launchpad set image deployment/launchpad-api launchpad-api=launchpad-api:v2
kubectl -n launchpad rollout status deployment/launchpad-api
kubectl -n launchpad get pods -w                           # in another terminal: watch old and new pods overlap
kubectl -n launchpad rollout history deployment/launchpad-api
kubectl -n launchpad rollout undo deployment/launchpad-api # back to :dev
```

(The container name in `set image` must match the `name:` of your container.)

7. **Zero-downtime test (optional, very instructive).** Run a client inside the cluster while you restart the deployment:

```bash
kubectl -n launchpad run curl --rm -it --image=curlimages/curl --restart=Never -- \
  sh -c 'while true; do curl -s -o /dev/null -w "%{http_code} " http://launchpad-api/readyz; sleep 0.2; done'
# other terminal:
kubectl -n launchpad rollout restart deployment/launchpad-api
```

You want a stream of `200` with no `000` or `5xx`. Remove the `preStop` hook and try again: do you see errors now?

## Done when

`labs/L04-probes-rollouts/check.sh` passes. Then do the debugging drills in `drills/`.

## Say it out loud

> "Readiness decides whether a pod receives traffic; liveness decides whether it gets restarted. I never point liveness at a dependency, or one slow database restarts the whole fleet. Requests are what the scheduler reserves; the memory limit is enforced, and going over it gets the container OOMKilled. With maxUnavailable zero and a readiness probe, a rollout only removes an old pod after a new one is ready, and rollout undo takes me back in seconds."
