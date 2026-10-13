# Debugging drills (after L04)

Each drill starts a workload in the namespace `drills` that is broken in one realistic way. Interviewers love *"a pod is stuck — walk me through how you debug it"*. These drills give you the real output to talk about.

**Prerequisite:** the image `launchpad-api:dev` is loaded in the cluster (`scripts/load-image.sh`).

## How to run a drill

```bash
drills/run.sh d1          # start it
# investigate WITHOUT opening drills/d1.yaml
drills/reset.sh           # when you are done with all of them
```

## The tickets

Read only the ticket. Diagnose with `kubectl` the way you would in production.

| Drill | Ticket |
|---|---|
| d1 | "We deployed d1 and nothing is running." |
| d2 | "d2 keeps restarting. Nobody changed the code." |
| d3 | "d3 was applied ten minutes ago and the pods never started." |
| d4 | "The d4 pods are Running and Ready, but calls to the d4 Service fail." |
| d5 | "d5 pods are Running but the Service has no traffic." |
| d6 | "d6 starts, then dies a moment later, again and again." |
| d7 | "d7 restarts every few seconds and never becomes ready, but the app logs show no error." |

## Your toolkit (in the order you would use it)

```bash
kubectl -n drills get pods                          # STATUS, READY, RESTARTS
kubectl -n drills describe pod <pod>                # Events at the bottom: the most useful lines
kubectl -n drills logs <pod>                        # logs of the current container
kubectl -n drills logs <pod> --previous             # logs of the container that just crashed
kubectl -n drills get events --sort-by=.lastTimestamp
kubectl -n drills get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'
kubectl -n drills get endpointslices                # who is behind each Service
kubectl -n drills run curl --rm -it --image=curlimages/curl --restart=Never -- curl -sv http://d4
```

## For each drill, write one line in English

> **Symptom** (what `get pods` showed) → **evidence** (the command and the line that told you) → **cause** → **fix**.

Example of the shape: *"The pod was Pending; describe showed 'Insufficient memory' in the events; the request was larger than any node; I lowered the request."*

Fix the YAML, apply it, confirm it works. The answers are in `solutions.zip → drills/ANSWERS.md`. Check them **after** your line is written.
