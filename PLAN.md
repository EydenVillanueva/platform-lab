# Interview sprint plan

Same plan as the printed **Interview-Sprint-Plan.pdf** (which also has the tracker, the checklists and the date-change rules).

- **Phase 1 · Screening week (Oct 12–19):** screening assumed Monday Oct 19.
- **Phase 2 · Technical week (Oct 20–26):** only if the screening goes well.
- **Rhythm:** 5 strong days (120 min) + 2 light days (45 min) per week.
- **Types:** T theory (Guide) · P practice · R active review · M mock with your mentor.
- **Mentor commands:** `Hint 1 — Lxx` · `Hint 2 — Lxx` · `Review — Lxx` · `Explain — concept` · `Mock S` (screening) · `Mock K` (technical questions) · `Mock X` (platform design) · `Mock P` (lab walkthrough).

---

## Phase 1 · Screening week

### Day 0 · Mon Oct 12, tonight · optional · 40 min · *Setup*

**Goal.** Every tool installed and the cluster running, so tomorrow starts with real work.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | P | 40 | **Setup:** install the tools, `scripts/doctor.sh`, `scripts/cluster-up.sh`, create the GitHub repository, set the AWS budget alert. | L00 | |

**By tonight:** `scripts/doctor.sh` shows no FAIL under week 1. · `kubectl get nodes` shows three Ready nodes.

**If behind:** Too tired tonight? Skip it. Day 1 starts with this block and reads G1 on Wednesday instead.

**If ahead:** Read G11.1–11.3 tonight; tomorrow's first block becomes writing your introduction.

### Day 1 · Tue Oct 13 · strong day · 120 min · *Your story, and Docker done right*

**Goal.** Start the introduction you will refine all week, and make your Dockerfile pass every check.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 15 | What the screening checks; the introduction; the honest Kubernetes and Terraform answers. | G11.1–11.3 · p. 49 | |
| ☐ | P | 15 | **Introduction, bullets only:** present → past → future, pointed at the platform role. Correct every fact in the draft. | NOTES.md | |
| ☐ | T | 30 | Containers and Docker (1.5–1.6 can be skimmed). | G1 · p. 2 | |
| ☐ | P | 50 | **Dockerfile** and `.dockerignore` until the check passes. | L01 | |
| ☐ | R | 10 | Explain your Dockerfile line by line, out loud, in English. Record 60 seconds. | L01 “Say it” | |

**By tonight:** Introduction bullets written. · `labs/L01-dockerfile/check.sh` passes.

**If behind:** L01 not passing: finish it in the first 30 minutes of Day 3 and move Day 3's reading (block 2) to the end of Day 3.

**If ahead:** Do the L01 stretch (multi-architecture build), or read G2.1–2.2 to lighten tomorrow.

### Day 2 · Wed Oct 14 · light day · 45 min · *The Kubernetes model*

**Goal.** Understand what you are about to deploy into, before you touch it.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 30 | Why Kubernetes, architecture, reconciliation, Pods/ReplicaSets/Deployments, Services. | G2.1–2.5 · p. 7 | |
| ☐ | R | 15 | Docker questions out loud; mark ✓ or ↻. | Q1–Q10 · p. 53 | |

**By tonight:** You can draw the control plane from memory. · Q1–Q10 marked.

**If behind:** Read G2.3–2.5 tomorrow instead of block 1 of Day 3 (the drawing).

**If ahead:** Read G2.6–2.7 and G3.1 now; Day 3 then has 15 extra minutes for L03.

### Day 3 · Thu Oct 15 · strong day · 120 min · *First deployment*

**Goal.** Your image running as two replicas behind a Service, configured from a ConfigMap and a Secret.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | R | 10 | On paper, from memory: the control plane, and what happens between `kubectl apply` and a running pod. | G2.2–2.3 · p. 7 | |
| ☐ | T | 15 | Labels and namespaces, other workloads; ConfigMaps and Secrets. | G2.6–2.7, 3.1 · p. 10 | |
| ☐ | P | 50 | **First deployment** on kind. | L02 | |
| ☐ | P | 30 | **Configuration and secrets.** | L03 | |
| ☐ | P | 15 | **Record your introduction** (take 1, 90 seconds). Listen once; fix the bullets. | G11.2 · p. 49 | |

**By tonight:** L02 and L03 checks pass. · Introduction take 1 recorded.

**If behind:** L03 unfinished: do it at the start of Day 4 and shorten Day 4's drills to d1 and d2.

**If ahead:** Delete a pod and a node's pods (`kubectl drain` a worker) and watch the ReplicaSet heal; explain it out loud.

### Day 4 · Fri Oct 16 · strong day · 120 min · *Production behaviour and debugging*

**Goal.** Probes, resources, rollouts and rollback working; four real failures diagnosed in English.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 30 | Probes, resources and QoS, rollouts, graceful shutdown; the debugging playbook. | G3.2–3.5, 3.9 · p. 12 | |
| ☐ | P | 45 | **Probes, resources, rolling update, rollback.** | L04 | |
| ☐ | P | 25 | **Drills d1, d2, d3, d5:** one English line each (symptom → evidence → cause → fix). | drills/ | |
| ☐ | R | 20 | Kubernetes questions out loud, fast; mark ↻ for Sunday. | Q11–Q30 · p. 53 | |

**By tonight:** L04 check passes. · Four drill lines written.

**If behind:** Drills unfinished: do d1 and d2 only. L04 unfinished: it takes block 1 of Day 5, and Day 5's reading becomes Sunday's.

**If ahead:** Drills d4, d6, d7; then compare all your lines with the answers in solutions.zip.

### Day 5 · Sat Oct 17 · strong day · 120 min · *CI and infrastructure as code*

**Goal.** The image built by GitHub Actions runs in your cluster; your first Terraform written by hand.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 20 | GitHub Actions anatomy; a container pipeline; OIDC. | G8.1–8.3 · p. 35 | |
| ☐ | P | 50 | **CI workflow**: test on PRs, build and push to GHCR on main, run that image in the cluster. Then `scripts/milestone1.sh`. | L05 | |
| ☐ | T | 25 | Terraform: the model, building blocks, state and locking, `for_each`. | G7.1–7.4 · p. 31 | |
| ☐ | P | 25 | **Terraform, part 1:** write `network.tf`, `ecr.tf`, `outputs.tf` by hand. No apply yet. | L06 | |

**By tonight:** `scripts/milestone1.sh`: L01–L05 passing. · Terraform files written (they may not validate yet).

**If behind:** Milestone 1 first: finish L05 even if Terraform waits. L06 then becomes plan-only on Sunday.

**If ahead:** Read G6.1–6.4 now; Sunday gets 20 minutes back for the stories.

### Day 6 · Sun Oct 18 · strong day · 120 min · *Dress rehearsal for the screening*

**Goal.** Everything you will say tomorrow, said out loud at least once, under realistic pressure.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | P | 20 | **Terraform, part 2:** `fmt`, `scripts/tf-guard.sh` until the plan passes. Apply and destroy only if time allows. | L06 | |
| ☐ | T | 20 | AWS networking essentials: public vs private, NAT, security groups, trace a request. | G6.1–6.4, 6.9–6.10 · p. 25 | |
| ☐ | T | 15 | Platform engineering in one page; your experience in platform language. | G9.1–9.3, 9.7 · p. 40 | |
| ☐ | P | 20 | **Stories:** bullets for four (fabric.inc integrations, Obok scan scheduling, a production problem, a standard you set). Tell two out loud. | G11.4 · p. 50 | |
| ☐ | M | 40 | **Mock S** with your mentor: a full screening simulation in English, then feedback. | chat | |
| ☐ | R | 5 | Write the three most important fixes from the mock in NOTES.md. | NOTES.md | |

**By tonight:** Mock S done, three fixes written; the screening-ready checklist mostly ticked. · Stop. No new material after the mock.

**If behind:** Never skip Mock S. Cut in this order: Terraform part 2 (say “I wrote it and planned it”), then the networking reading.

### Day 7 · Mon Oct 19 · interview day · 45 min · *Screening interview (assumed date)*

**Goal.** Arrive warm, rested and with your three fixes in mind.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | R | 10 | Reread your introduction bullets and the fixes in NOTES.md. | NOTES.md | |
| ☐ | P | 10 | Introduction out loud, twice, standing up. | G11.2 · p. 49 | |
| ☐ | P | 10 | The Kubernetes answer and one story, out loud. | G11.3–11.4 · p. 50 | |
| ☐ | R | 15 | Logistics checklist on the protocol page. | this plan | |

**By tonight:** Every question you were asked is written down and sent to your mentor. · Thank-you note to the recruiter sent.

**If behind:** If the interview moved: follow “If the dates change”.

---

## Phase 2 · Technical week

### Day 8 · Tue Oct 20 · strong day · 120 min · *Debrief, and AWS for real*

**Goal.** Learn from the screening, then put your network and registry in a real AWS account.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | R | 15 | **Debrief:** every question from the screening, what went well, what to fix. Send it to your mentor; adjust the week if the technical format is known. | chat | |
| ☐ | T | 30 | Endpoints and PrivateLink, IAM, connecting networks, DNS; OIDC again. | G6.5–6.8, 8.3 · p. 27 | |
| ☐ | P | 25 | **Terraform, part 3:** apply, run the check while it exists, destroy, run the leftovers script. | L06 | |
| ☐ | P | 35 | **OIDC, part 1:** write `oidc.tf` and the `push-ecr` job. No apply yet. | L07 | |
| ☐ | R | 15 | Networking and IAM questions out loud. | Q43–Q52 · p. 55 | |

**By tonight:** L06 check passed on applied infrastructure, then destroyed. · `oidc.tf` and the job written.

**If behind:** Skip the apply of L06 (it is repeated on Day 10 anyway); keep the OIDC writing.

**If ahead:** Read G7.5–7.8 (modules, drift, Terraform in CI).

### Day 9 · Wed Oct 21 · light day · 45 min · *Helm*

**Goal.** Understand charts, values and releases before you build one.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 30 | Helm: charts, values, releases, rollbacks, the checksum trick. | G4.1–4.3 · p. 18 | |
| ☐ | R | 15 | Helm and GitOps questions out loud. | Q31–Q36 · p. 54 | |

**By tonight:** Q31–Q36 marked.

**If behind:** Read G4.1–4.3 at the start of Day 10 and shorten Mock K to 10 minutes.

**If ahead:** Run `helm create` in a scratch folder and read what it generates.

### Day 10 · Thu Oct 22 · strong day · 120 min · *Keyless CI to AWS, and a Helm chart*

**Goal.** An image pushed to ECR with no stored keys; the service packaged as a chart.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | P | 50 | **OIDC, part 2:** apply, set repository variables, push to main, see the image in ECR, then destroy. | L07 | |
| ☐ | P | 50 | **Helm chart** with dev and prod values; upgrade and roll back. | L08 | |
| ☐ | M | 20 | **Mock K #1**: 20 minutes of rapid technical questions (Docker, Kubernetes, AWS, Terraform). | chat | |

**By tonight:** L07 check passed, AWS destroyed, leftovers clean. · L08 check passes.

**If behind:** L07 apply is the first cut (explain it from your code and the solution); keep L08.

**If ahead:** Add the Gateway API stretch to the chart.

### Day 11 · Fri Oct 23 · strong day · 120 min · *EKS, autoscaling and the rest of the drills*

**Goal.** Say what changes on EKS; watch your own service scale out under load.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 30 | Kubernetes on AWS: EKS, compute options, VPC CNI, pod identity, upgrades, ECS vs EKS. | G5 · p. 21 | |
| ☐ | P | 30 | **Autoscaling:** metrics-server, HPA in the chart, load, scale out. | L09 | |
| ☐ | P | 30 | **Drills d4, d6, d7** (and any of d1–d5 you skipped). Compare with the answers. | drills/ | |
| ☐ | R | 30 | EKS and Terraform questions out loud. | Q37–Q42 · p. 54; Q53–Q60 · p. 55 | |

**By tonight:** L09 check passes. · All seven drill lines written.

**If behind:** L09 becomes reading (G3.6); keep the EKS chapter and the drills.

**If ahead:** Read G8.4–8.8 (CI at scale, strategies, branching, supply chain).

### Day 12 · Sat Oct 24 · strong day · 120 min · *Platform design*

**Goal.** Lead a platform design discussion with structure and trade-offs.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | T | 25 | The framework for platform roles; read prompts P1–P5 (not the outlines). | G10 · p. 45 | |
| ☐ | M | 45 | **Mock X #1**: a platform design scenario you have not seen. | chat | |
| ☐ | T | 30 | CI/CD at scale, deployment strategies, Gitflow vs trunk-based, supply chain; the rest of the platform chapter. | G8.4–8.8, 9.4–9.6 · p. 37 | |
| ☐ | R | 20 | CI/CD and platform questions out loud. | Q61–Q75 · p. 55 | |

**By tonight:** Mock X #1 done; the scenario outline you missed most is read. · Q61–Q75 marked.

**If behind:** Keep the mock; move block 3 to Sunday's review block.

**If ahead:** Work P4 (ECS to EKS migration) out loud on your own: it is your strongest bridge.

### Day 13 · Sun Oct 25 · strong day · 120 min · *Dress rehearsal for the technical interview*

**Goal.** Your lab told as a work project, and every weak question re-tested.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | M | 30 | **Mock P**: walk your mentor through the whole lab as a work project; why each choice; what you would change in production. | chat | |
| ☐ | M | 40 | **Mock X #2**, or **Mock K #2** if the technical format is question-based. | chat | |
| ☐ | T | 20 | Kustomize, GitOps, modules, drift, Terraform in CI. | G4.4–4.5, 7.5–7.8 · p. 19 | |
| ☐ | R | 30 | Every ↻ question, then ten random ones. | Q bank | |

**By tonight:** Both mocks done; fixes in NOTES.md. · Stop. No new material.

**If behind:** Never cut the mocks; cut the reading.

**If ahead:** L10 golden-path stretch, only if you are fresh.

### Day 14 · Mon Oct 26 · interview day · 45 min · *Technical interview (or final review)*

**Goal.** Warm up, not cram.

| ☐ | Type | Min | What | Where | Real |
|---|---|---|---|---|---|
| ☐ | R | 15 | Reread NOTES.md and the “Say it” boxes of chapters 2, 3, 6 and 8. | Guide | |
| ☐ | P | 15 | Introduction, the Kubernetes answer and one story out loud. | G11.2–11.4 · p. 49 | |
| ☐ | R | 15 | Choose four questions for the client; logistics checklist. | G11.5 · p. 51 | |

**By tonight:** Every question you were asked is written down and sent to your mentor.

**If behind:** If the interview is later: repeat Day 13's review block on the remaining days, plus one mock per strong day.
