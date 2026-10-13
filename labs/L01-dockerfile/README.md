# L01 · A production Dockerfile for a Node service

**Read first:** Guide chapter 1 (Containers and Docker).
**You write:** `app/Dockerfile` and `app/.dockerignore`. You do not touch the app code.

## Why interviewers care

"Write or review a Dockerfile" is the most common hands-on question for platform roles. They look for: small images, reproducible installs, layer caching, no root, and correct signal handling.

## Tasks

1. Write `app/.dockerignore`. At minimum exclude `node_modules`, `test`, `.git`, and any `*.log`.
2. Write a **multi-stage** `app/Dockerfile`:
   - Stage 1 (`deps`): from a **pinned** Node 22 base image (for example `node:22-alpine` or `node:22-bookworm-slim`, never `:latest`). Copy **only** `package.json` and `package-lock.json` first, then install **production dependencies only** with `npm ci`.
   - Stage 2 (runtime): start again from a small base, copy `node_modules` from stage 1 and the `src/` folder from the build context.
   - Accept two build arguments, `APP_VERSION` and `GIT_SHA`, and expose them to the app as environment variables with the same names (the app reports them at `/version`).
   - Set `NODE_ENV=production`, document port 8080 with `EXPOSE`.
   - Run as a **non-root user** (the official Node images already include a user called `node`).
   - Start with the **exec form**: `CMD ["node", "src/server.js"]`.
3. Build and run it by hand once:

```bash
docker build -t launchpad-api:dev --build-arg APP_VERSION=dev app/
docker run --rm -p 8080:8080 launchpad-api:dev
curl localhost:8080/version          # in another terminal
docker images launchpad-api          # how big is it?
```

4. Press Ctrl+C in the terminal running the container. It should stop **immediately**. If it takes ~10 seconds, your process is not receiving SIGTERM.

## Done when

```bash
labs/L01-dockerfile/check.sh
```

passes. It builds your image, checks its size and user, starts it, calls `/readyz` and `/version`, then runs `docker stop` and verifies the container exited with code 0 in under 5 seconds.

## Stretch

- Change one line in `src/app.js`, rebuild, and watch which layers come from cache. Then move `COPY src` above `npm ci` and rebuild twice: what happens to the build time, and why?
- Build for two architectures: `docker buildx build --platform linux/amd64,linux/arm64 -t launchpad-api:multi app/`. Your Mac is arm64; most cloud nodes are amd64. What error do you get when the architecture is wrong?

## Say it out loud (record yourself, 60 seconds)

> "My Dockerfile has two stages. The first one installs production dependencies with npm ci, copying the lockfile first so that layer is cached until dependencies change. The runtime stage only has node_modules and the source, runs as a non-root user, and starts node directly so it receives SIGTERM and shuts down gracefully."
