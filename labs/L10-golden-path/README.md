# L10 · Stretch: a golden-path CLI (developer experience)

**Only if you are on schedule.** This is the lab where your strongest skill (Node.js) meets the platform role.
**Read first:** Guide chapter 9 (platform engineering and developer experience).
**You write:** `tools/create-service/src/generate.js`. Everything else (CLI wrapper, templates, tests) is given.

## Why interviewers care

"Developer Platform: experience creating internal developer tools, self-service platforms…" is in the job description. A golden path is the smallest real example: one command gives a team a new service that already follows the platform's standards (Dockerfile, CI, deployment values, an owner in the catalog). You can describe this in the interview as something you built, with its trade-offs.

## Tasks

1. Read `tools/create-service/test/generate.test.js`. The tests are the specification.
2. Implement `validateName`, `renderTemplate` and `generateService` in `src/generate.js`.
3. Run the tests until they pass:

```bash
node --test tools/create-service/test/generate.test.js
```

4. Try it:

```bash
node tools/create-service/index.js --name orders-api --port 8081 --team payments --out /tmp/services
find /tmp/services/orders-api -type f
```

## Done when

`labs/L10-golden-path/check.sh` passes.

## Questions to answer out loud

- Why does `renderTemplate` have to leave `${{ github.sha }}` alone?
- Why render everything in memory before writing any file?
- A template is now the standard for 30 services. How do you roll out a change to all of them? (Think: templates generate once; a shared chart or reusable workflow is referenced and updated in one place.)

## Say it out loud

> "I built a small golden-path generator: one command creates a service with our Dockerfile, CI workflow, Helm values and a Backstage catalog entry with an owner. It validates input and never overwrites. The trade-off of generators is drift: generated files diverge over time, so the shared pieces, like the chart and the reusable CI workflow, should be referenced rather than copied."
