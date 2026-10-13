# L03 · Configuration and secrets

**Read first:** Guide 3.1 (ConfigMaps and Secrets).
**You write:** `k8s/configmap.yaml` and changes to `k8s/deployment.yaml`. The Secret is created with a command, **not** stored in git.

## Why interviewers care

"How do you handle configuration and secrets per environment?" is guaranteed. The expected answer: the same image everywhere, configuration injected at runtime, secrets never in the repository, and a clear path to a real secret manager.

## Tasks

1. Create `k8s/configmap.yaml`: ConfigMap `launchpad-config` in `launchpad` with `APP_ENV: dev` and a `GREETING` of your choice.
2. Create the Secret from the command line (it does not go into `k8s/`):

```bash
kubectl -n launchpad create secret generic launchpad-secret --from-literal=API_KEY=change-me-123
kubectl -n launchpad get secret launchpad-secret -o yaml      # look at the data: is it encrypted?
echo 'Y2hhbmdlLW1lLTEyMw==' | base64 --decode
```

3. Change the Deployment so the container gets:
   - every key of the ConfigMap as environment variables (`envFrom`),
   - `API_KEY` from the Secret (`valueFrom.secretKeyRef`),
   - `REQUIRE_API_KEY: "true"`, so the app refuses to start without a key.
4. Apply, then check what reached the container:

```bash
kubectl apply -f k8s/
kubectl -n launchpad port-forward svc/launchpad-api 8080:80
curl localhost:8080/config        # apiKeyConfigured should be true; the key itself is never shown
```

5. Experiment: change `GREETING` in the ConfigMap and apply. Does `/config` change? Now run `kubectl -n launchpad rollout restart deployment/launchpad-api`. Why was the restart needed?

## Done when

`labs/L03-config-secrets/check.sh` passes.

## Say it out loud

> "Configuration lives in a ConfigMap and is injected as environment variables, so the same image runs in every environment. Secrets are only base64-encoded in Kubernetes, so I keep them out of git and, on AWS, I'd source them from Secrets Manager with the External Secrets Operator and encrypt etcd with KMS."
