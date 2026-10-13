# Hints

Read **Hint 1** first and try again for 10 minutes before reading **Hint 2**. Neither contains the answer; the reference solutions are in `solutions.zip`.

---

## L01 · Dockerfile

**Hint 1.** Docker caches each instruction as a layer and reuses it until something it depends on changes. Ask yourself which files change every day (your code) and which change rarely (the dependency list), and order the `COPY` instructions accordingly. For the shutdown test: who is PID 1 inside your container, and does it receive the signal `docker stop` sends?

**Hint 2.** Shape: `FROM <pinned node image> AS deps` → `WORKDIR` → copy the two package files → `npm ci` without dev dependencies. Then a second `FROM <pinned node image>` → copy `node_modules` from the first stage (`COPY --from=deps`) and `package.json` and `src/` from the context → `ARG` + `ENV` for the version → `USER node` → `EXPOSE` → `CMD` in JSON-array form. The app reads `package.json` at runtime, so it has to be in the image.

## L02 · First deployment

**Hint 1.** Three objects, three files. The Deployment's `selector.matchLabels` and its pod `template.metadata.labels` must agree, and the Service's `selector` must match the same labels. If pods do not start, `kubectl describe pod` and read the Events at the bottom.

**Hint 2.** Deployment: `apiVersion: apps/v1`, `spec.replicas`, `spec.selector.matchLabels`, `spec.template.metadata.labels`, `spec.template.spec.containers[]` with `name`, `image`, `imagePullPolicy`, `ports[].containerPort`. Service: `apiVersion: v1`, `spec.type`, `spec.selector`, `spec.ports[]` with `port` and `targetPort`. Both need `metadata.namespace: launchpad`. Apply the namespace before the rest: `kubectl apply -f k8s/` processes files in alphabetical order, so on the very first run the Deployment can arrive before its namespace.

## L03 · Config and secrets

**Hint 1.** There are two ways to get configuration into environment variables: every key of a ConfigMap at once, or one variable at a time from a key. You need the first for the ConfigMap and the second for the Secret. Environment variables are read when the process starts.

**Hint 2.** In the container: `envFrom: - configMapRef: { name: … }` and `env: - name: API_KEY, valueFrom: { secretKeyRef: { name: …, key: … } }`. Every `value:` in `env` is a string, so `"true"` needs quotes. After changing the ConfigMap: `kubectl rollout restart`.

## L04 · Probes, resources, rollouts

**Hint 1.** Three questions decide each probe: what should happen when it fails (restart, or stop sending traffic?), what endpoint answers that question, and how long the app may legitimately be "not ready". A `startupProbe` protects a slow starter from the liveness probe until it has started once.

**Hint 2.** Under the container: `readinessProbe.httpGet {path, port}`, `livenessProbe.httpGet {…}`, `startupProbe.httpGet {…}` with `failureThreshold × periodSeconds` ≥ the startup time, `resources.requests {cpu, memory}`, `resources.limits {memory}`, `lifecycle.preStop.sleep.seconds`. Under the Deployment `spec`: `strategy.type: RollingUpdate` and `strategy.rollingUpdate {maxUnavailable: 0, maxSurge: 1}`. The container name you use in `kubectl set image` is the `name:` of the container, not the Deployment's.

## L05 · CI

**Hint 1.** Think in jobs: one job that tests (for every PR and push), one that builds and publishes (only after tests pass, only from `main`). Each job runs on a fresh machine, so each one checks out the code. The workflow-level `permissions` should be minimal; the publishing job asks for more.

**Hint 2.** `on: { pull_request: {}, push: { branches: [main] } }`. Test job: `actions/checkout`, `actions/setup-node` (`node-version`, `cache: npm`, `cache-dependency-path: app/package-lock.json`), `defaults.run.working-directory: app`. Image job: `needs: test`, `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`, `permissions: { contents: read, packages: write }`, then `docker/setup-buildx-action`, `docker/login-action` (registry `ghcr.io`, password `secrets.GITHUB_TOKEN`), `docker/build-push-action` with `context: app`, `push: true`, `tags`, `build-args`, `cache-from/cache-to: type=gha`. For lowercase: bash `${VAR,,}` in a `run` step that writes to `$GITHUB_OUTPUT`.

## L06 · Terraform network

**Hint 1.** Start from the VPC and work outwards: subnets belong to the VPC, the internet gateway attaches to the VPC, a route table says where traffic goes, and an association says which subnets use which table. A subnet is public **only** because its route table sends `0.0.0.0/0` to an internet gateway. For four similar subnets, describe them as data (a map in `locals`) and create them from that data.

**Hint 2.** `data "aws_availability_zones"` → `locals { subnets = { public-a = { cidr, az, public = true }, … } }` → `resource "aws_subnet" "this" { for_each = local.subnets … }`. Tags with a computed key: `(each.value.public ? "kubernetes.io/role/elb" : "kubernetes.io/role/internal-elb") = "1"`. Associations: another `for_each` over the same map, choosing the route table with a conditional. Endpoint: `aws_vpc_endpoint` with `vpc_endpoint_type = "Gateway"`, `service_name = "com.amazonaws.<region>.s3"`, `route_table_ids`. Lifecycle policy: `jsonencode({ rules = [ … ] })`.

## L07 · OIDC and ECR

**Hint 1.** There are three pieces of trust: AWS must trust GitHub as an identity provider; a role must trust tokens from that provider **only** for your repository and branch; and the role's permissions must allow pushing to one repository. In the workflow, the job has to be allowed to ask GitHub for a token.

**Hint 2.** `aws_iam_openid_connect_provider` (url, `client_id_list`) → `data "aws_iam_policy_document"` with `actions = ["sts:AssumeRoleWithWebIdentity"]`, `principals { type = "Federated", identifiers = [provider arn] }` and two `condition` blocks (`StringEquals` on `token.actions.githubusercontent.com:aud` and `…:sub`) → `aws_iam_role` → a second policy document (login on `*`, push actions on the repository ARN) → `aws_iam_role_policy`. Workflow: `permissions: { id-token: write, contents: read }`, `aws-actions/configure-aws-credentials` with `role-to-assume` and `aws-region`, `aws-actions/amazon-ecr-login` (`id: ecr`), and tag `${{ steps.ecr.outputs.registry }}/launchpad-api:${{ github.sha }}`. Plans need your repository: create `infra/terraform.tfvars` from the example.

## L08 · Helm

**Hint 1.** A chart is your L02–L04 YAML with the parts that differ between environments replaced by `{{ .Values.something }}`. Decide what an environment is allowed to change (replicas, config, resources, image tag) and keep everything else fixed in the templates. To restart pods when the config changes, something in the pod template must change too.

**Hint 2.** Names: `{{ include "<chart>.fullname" . }}` defined in `_helpers.tpl` as the release name. ConfigMap data: `{{- range $k, $v := .Values.config }}` with `{{ $v | quote }}`. Resources: `{{- toYaml .Values.resources | nindent 12 }}`. Checksum: `checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}` under `spec.template.metadata.annotations`. Inspect with `helm template` before every install.

## L09 · Autoscaling

**Hint 1.** The HPA needs three things: a metrics source, a target to scale, and a percentage that only means something if the pods declare CPU **requests**. Helm and the HPA must not fight over the replica count.

**Hint 2.** `{{- if .Values.autoscaling.enabled }} … {{- end }}` around the whole HPA file; `apiVersion: autoscaling/v2`, `scaleTargetRef {apiVersion: apps/v1, kind: Deployment, name}`, `minReplicas`, `maxReplicas`, `metrics: - type: Resource, resource: { name: cpu, target: { type: Utilization, averageUtilization } }`. In the Deployment: `{{- if not .Values.autoscaling.enabled }} replicas: … {{- end }}`.

## L10 · Golden path (stretch)

**Hint 1.** Make the tests pass one `test(...)` at a time, in file order. For the template function, the difficult case is telling `{{name}}` apart from `${{ github.sha }}`: look at the character just before the braces. For safety, do all the work that can fail before writing anything to disk.

**Hint 2.** `validateName`: four checks in order (length, allowed characters, first character, last character), each returning `{ ok: false, reason }`. `renderTemplate`: `text.replace(/(?<!\$)\{\{\s*([A-Za-z_]\w*)\s*\}\}/g, (match, key) => …)` and throw if `key` is not in `vars`. `generateService`: validate → check the target folder does not exist → read and render every `.tmpl` into an array → then `mkdirSync({ recursive: true })` and `writeFileSync` each → return the sorted relative paths.
