# L05 · Continuous integration with GitHub Actions

**Read first:** Guide chapter 8 (sections 8.1 and 8.2).
**You write:** `.github/workflows/ci.yml`.

## Why interviewers care

The role asks for "advanced CI/CD". You already use pipelines; the step up is being able to **design** one and explain each choice: when it runs, what it caches, how images are tagged, who can push, how it fails.

## Tasks

Write `.github/workflows/ci.yml` with:

1. **Triggers:** `pull_request` (any branch) and `push` to `main`.
2. **Job `test`:** Ubuntu runner, check out the code, set up Node 22 with the npm cache, then `npm ci` and `npm test` **inside `app/`**.
3. **Job `image`:** runs only after `test` succeeds (`needs`) and only on pushes to `main`.
   - Permissions: `contents: read`, `packages: write` (nothing more).
   - Log in to **GitHub Container Registry** (`ghcr.io`) with the built-in `GITHUB_TOKEN`.
   - Build `app/` with Buildx and push `ghcr.io/<your-user>/launchpad-api:<commit SHA>`. GHCR requires the name in **lowercase**.
   - Pass `APP_VERSION` and `GIT_SHA` as build arguments.
   - Use the GitHub Actions cache for Docker layers.
4. Push to `main`, open the **Actions** tab and fix it until it is green. Then open a pull request with a tiny change: only `test` should run.
5. **Use the CI image in your cluster** (this is your week 1 milestone):

```bash
docker pull ghcr.io/<you>/launchpad-api:<sha>      # docker login ghcr.io first if the package is private
kind load docker-image ghcr.io/<you>/launchpad-api:<sha> --name platform-lab
kubectl -n launchpad set image deployment/launchpad-api launchpad-api=ghcr.io/<you>/launchpad-api:<sha>
kubectl -n launchpad rollout status deployment/launchpad-api
```

Then update `k8s/deployment.yaml` with that image so git and the cluster agree.

## Done when

`labs/L05-ci/check.sh` passes, then `scripts/milestone1.sh` for the whole week.

## Stretch

- A third job `manifests` that validates `k8s/*.yaml` with kubeconform.
- `concurrency:` so two pushes to the same branch do not build at the same time.

## Say it out loud

> "Pull requests run the tests only. A merge to main builds the image once, tags it with the commit SHA so every deployment is traceable and immutable, and pushes it with a token scoped to packages. The same image is then promoted across environments instead of being rebuilt."
