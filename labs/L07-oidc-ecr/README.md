# L07 · GitHub Actions → AWS without access keys (OIDC) and a push to ECR

**Read first:** Guide 8.3 (OIDC) and 6.6 (IAM in one page).
**You write:** `infra/oidc.tf` (plus a `github_repo` variable and a `github_actions_role_arn` output) and a new job in `.github/workflows/ci.yml`.

## Why interviewers care

"How does your pipeline authenticate to AWS?" A platform engineer's answer is never "with an access key in a secret". It is short-lived credentials via OIDC, a role trusted only by one repository and branch, and a policy that can push to one repository and nothing else.

## Tasks

1. **IAM in Terraform** (`infra/oidc.tf`):
   - The GitHub OIDC identity provider: URL `https://token.actions.githubusercontent.com`, audience (`client_id_list`) `sts.amazonaws.com`.
     *If your account already has this provider (you can only have one per URL), read it with a `data` block instead of creating it.*
   - A role `platform-lab-gha-ecr` whose **trust policy** allows `sts:AssumeRoleWithWebIdentity` from that provider **only when**:
     - `token.actions.githubusercontent.com:aud` equals `sts.amazonaws.com`, and
     - `token.actions.githubusercontent.com:sub` equals `repo:<you>/<repo>:ref:refs/heads/main`.
   - A policy on that role that allows `ecr:GetAuthorizationToken` (it only works on `*`) and the push actions **on the launchpad-api repository ARN only**.
   - Write the policies with `data "aws_iam_policy_document"`, not inline JSON strings.
2. Apply through the guard (the L06 network can be applied together; it is all free):

```bash
scripts/tf-guard.sh && (cd infra && terraform apply tfplan)
gh variable set AWS_ROLE_ARN --body "$(terraform -chdir=infra output -raw github_actions_role_arn)"
gh variable set AWS_REGION --body us-east-1
```

3. **New job `push-ecr`** in `ci.yml`: needs `test`, only on `main`, permissions `id-token: write` and `contents: read`. Steps: checkout → `aws-actions/configure-aws-credentials` with `role-to-assume: ${{ vars.AWS_ROLE_ARN }}` → `aws-actions/amazon-ecr-login` → build and push `<registry>/launchpad-api:<sha>`.
4. Push to main. Then verify and **destroy**:

```bash
aws ecr describe-images --repository-name launchpad-api --query 'imageDetails[].imageTags' --output text
labs/L07-oidc-ecr/check.sh
terraform -chdir=infra destroy && scripts/aws-leftovers.sh
```

After the destroy, the `push-ecr` job will fail on the next push. That is expected: disable it with `if: false` or apply again when you want to use it.

## Done when

`labs/L07-oidc-ecr/check.sh` passes while the role exists and the image is in ECR.

## Questions to answer out loud

- What exactly does GitHub send to AWS, and what does AWS check before giving credentials?
- What would happen if the `sub` condition were `repo:<you>/*`?
- Why does `ecr:GetAuthorizationToken` need `*` when everything else is scoped to one repository?

## Say it out loud

> "The workflow requests an OIDC token from GitHub, and AWS STS exchanges it for temporary credentials only if the token's audience and subject match the role's trust policy, which pins the repository and the branch. There are no long-lived keys to rotate or leak, and the role can only push to one ECR repository."
