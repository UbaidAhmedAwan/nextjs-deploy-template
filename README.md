# nextjs-deploy-template

A small, opinionated Next.js 14 starter wired up the way I actually ship Node apps to AWS: standalone Docker build, image to ECR, rolling redeploy on ECS via the AWS CLI. No Terraform, no CDK, no CloudFormation — the infrastructure is provisioned once in the console and the pipeline only owns the application lifecycle.

## Stack

- **Next.js 14** (App Router) + React 18 + TypeScript
- **Tailwind CSS** for styling
- **ESLint + Prettier**
- **Docker** multi-stage build, `output: 'standalone'`
- **GitHub Actions** for CI (lint / typecheck / build) and deploy (ECR + ECS)
- **AWS CLI** for the deploy step — `aws ecs update-service --force-new-deployment`

## Run locally

```bash
cp .env.example .env.local
npm install
npm run dev
```

App on http://localhost:3000, health check on http://localhost:3000/api/health.

To exercise the production image the same way ECS will:

```bash
docker compose up --build
```

## Deploy

The GitHub Actions workflow assumes you've already created:

- An ECR repository
- An ECS cluster + service whose task definition pulls `:latest` from that repo
- An IAM role trusted by GitHub's OIDC provider with `ecr:*` and `ecs:UpdateService` on the relevant ARNs

Set these as repo-level **variables**: `AWS_REGION`, `ECR_REPOSITORY`, `ECS_CLUSTER`, `ECS_SERVICE`. Set the role ARN as a **secret**: `AWS_DEPLOY_ROLE_ARN`.

The deploy is wired to `workflow_dispatch` so you trigger it manually from the Actions tab. Uncomment the `push` block in `.github/workflows/deploy.yml` once you're happy with it.

For one-off manual deploys (or when CI is down):

```bash
export AWS_REGION=eu-west-1
export AWS_ACCOUNT_ID=123456789012
export ECR_REPOSITORY=nextjs-deploy-template
export ECS_CLUSTER=apps
export ECS_SERVICE=nextjs-deploy-template
./scripts/deploy.sh
```

## Why this layout

A few choices that aren't obvious from the file tree:

- **`output: 'standalone'`** — Next traces only the modules the server actually imports and copies them into `.next/standalone`. The runtime image stays small and you don't need `node_modules` in the container.
- **`/api/health` is a Route Handler, not a separate service.** The same Node process serves pages and the health endpoint, which is what the ALB target group hits. One process to watch, one log stream.
- **Force `dynamic` on the health route.** Otherwise Next would render it once at build time and `uptime` would lie about the running container.
- **`update-service --force-new-deployment` over rendering a new task definition.** The task def pins to `:latest`, so forcing a deployment is enough for a rolling update. Pin to immutable tags and render a new revision per deploy if you need point-in-time rollbacks; this template optimises for simplicity.
- **OIDC role assumption, not long-lived AWS keys in GitHub secrets.** Standard practice now and removes a credential rotation chore.
- **`--platform linux/amd64` in `scripts/deploy.sh`.** Building from an Apple Silicon laptop without this gives you an arm64 image that crashes immediately on Fargate amd64. Found this the hard way.
- **No DB or auth in the starter.** Everything here is real and runs; the moment you add a service you don't need, the template starts lying about what it does.

## Project layout

```
app/
  api/health/route.ts    # ALB health-check endpoint
  _components/           # client components, prefixed _ to opt out of routing
  layout.tsx
  page.tsx
scripts/deploy.sh        # manual ECR push + ECS redeploy
.github/workflows/
  ci.yml                 # lint + typecheck + build on every PR
  deploy.yml             # build, push to ECR, redeploy ECS
Dockerfile               # multi-stage: deps -> builder -> runner
docker-compose.yml       # parity check for the production image
```

## What this is not

It's not a starter for serverless Next on Vercel — if that's the target, delete the Dockerfile and workflows and you're done. It's not a monorepo template. It doesn't set up a database, a queue, or auth. Add those when you actually need them.
