# L02 · First deployment on Kubernetes

**Read first:** Guide chapter 2 (the model, Pods, Deployments, Services).
**You write:** `k8s/namespace.yaml`, `k8s/deployment.yaml`, `k8s/service.yaml`.

## Why interviewers care

Every platform interview assumes you can write a Deployment and a Service from memory and explain how traffic reaches a pod. This is the ECS service + target group you already know, with Kubernetes names.

## Tasks

1. Build the image and copy it into the cluster (kind cannot see images on your Mac's Docker otherwise):

```bash
scripts/load-image.sh          # builds launchpad-api:dev and runs "kind load docker-image"
```

2. Write the three manifests. Requirements:
   - Namespace `launchpad`.
   - Deployment `launchpad-api` in that namespace: **2 replicas**, label `app: launchpad-api` on the pods, container port **8080**, image `launchpad-api:dev`, `imagePullPolicy: IfNotPresent`.
   - Service `launchpad-api`, type `ClusterIP`, **port 80 → targetPort 8080**, selecting `app: launchpad-api`.
3. Apply and watch:

```bash
kubectl apply -f k8s/namespace.yaml           # first: the other files need the namespace to exist
kubectl apply -f k8s/
kubectl -n launchpad get pods -o wide -w       # which nodes did the scheduler pick?
kubectl -n launchpad port-forward svc/launchpad-api 8080:80
curl localhost:8080/                            # in another terminal
```

4. Delete one pod by name (`kubectl -n launchpad delete pod <name>`) and watch a new one appear. Which object created it, and why?

## Done when

`labs/L02-first-deploy/check.sh` passes.

## Questions to answer out loud before moving on

- What is the difference between the Deployment, the ReplicaSet and the Pod you just saw?
- How does the Service know which pods to send traffic to?
- Why did you need `imagePullPolicy: IfNotPresent` here, and what would `Always` do?

## Say it out loud

> "A Deployment declares that I want two replicas of this pod template. Its controller creates a ReplicaSet, and the ReplicaSet keeps two pods alive. The Service selects pods by label and load-balances across the ready ones, so pods can come and go without clients noticing."
