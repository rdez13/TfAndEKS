# TfAndEKS — Project Context

A learning project: provision an EKS cluster with Terraform, run GitOps with Argo CD, pull
secrets with External Secrets Operator, and ship a containerized app through a GitHub
Actions → ECR → Argo CD pipeline.

**Session tracking lives outside this repo** at
`/Users/Rayamba/Desktop/Prompts and Progress/TfAndEKSPnP/` — `instructions.md`,
`objectives.md`, `progress.md`. Read those at the start of every session.

---

## Critical: AWS account

Use the **`tfeks`** profile. Always.

| | |
|---|---|
| Account | `793593623012` |
| IAM user | `tf-admin` (`AdministratorAccess`) |
| Region | `us-east-1` |
| Profile | `tfeks` |

The machine's **`default` profile is a different, unrelated account** (`327123928594`, root
credentials, being closed). If anything falls back to the default profile, resources get
created in the wrong account. The Terraform AWS provider pins `profile = "tfeks"` explicitly
rather than relying on ambient credentials.

Verify before any apply:

```bash
aws sts get-caller-identity --profile tfeks   # must show 793593623012
```

Note: in zsh, `P="--profile tfeks"; aws sts get-caller-identity $P` does **not** work —
zsh doesn't word-split unquoted expansions. Use `export AWS_PROFILE=tfeks` instead.

---

## Repository layout

Mono-repo. Argo CD watches the `k8s/` path of this same repo.

```
terraform/
  bootstrap/      S3 state bucket (applied once with local state)
  *.tf            VPC, EKS, ECR, IAM/IRSA, addons, secrets, GitHub OIDC
app/
  Dockerfile      nginx serving a static page
  index.html      displays a value sourced from a secret
k8s/
  app/                    Deployment, Service, Ingress, Namespace, kustomization
  external-secrets/       ClusterSecretStore + ExternalSecret
  argocd/
    app-of-apps.yaml      root Application — the one manual kubectl apply
    applications/         child Applications
.github/workflows/
  build-push.yml  build → ECR → bump image tag → commit back
```

---

## Architecture decisions

| Decision | Choice | Why |
|---|---|---|
| Repo layout | Single mono-repo | Simplest; CI loop avoided with path filters + `[skip ci]` |
| Compute | Managed node group, 2x `t3.medium` | No Fargate DaemonSet/profile caveats |
| Secret store | AWS Secrets Manager | Canonical ESO backend, native JSON key/value |
| Ingress | AWS Load Balancer Controller | Real internet-facing ALB via `Ingress` |
| TF state | S3 with `use_lockfile = true` | Native S3 locking, no DynamoDB table needed |
| CI auth | GitHub OIDC → IAM role | No long-lived AWS keys in GitHub |
| VPC CIDR | `10.0.0.0/16` | Default VPC uses `172.31.0.0/16` — no overlap |

---

## Ordering constraints

Terraform installs Argo CD and ESO via Helm, but the `Application` and `ExternalSecret`
resources they manage live in Git. Bootstrap order:

1. `terraform/bootstrap` → S3 state bucket (local state)
2. `terraform/` → VPC, EKS, ECR, IRSA roles, Helm releases (LB controller, ESO, Argo CD)
3. Build and push an initial image to ECR so the first deploy has something to pull
4. `kubectl apply -f k8s/argocd/app-of-apps.yaml` — the only manual apply
5. Argo CD reconciles everything else from Git

---

## Teardown — read before destroying

**The ALB is created by the LB controller, not Terraform.** Terraform doesn't know it
exists, so it won't remove it, and the VPC delete will hang ~20 minutes on orphaned ENIs and
then fail.

Correct order:

```bash
kubectl delete -f k8s/argocd/app-of-apps.yaml   # stops Argo CD re-creating things
kubectl delete ingress --all -A                 # releases the ALB
# wait for the load balancer to disappear from the console
terraform destroy
```

Secrets Manager secrets use `recovery_window_in_days = 0` so repeated create/destroy cycles
don't collide with the default 7-day recovery window.

**Cost while running: ~$6.50/day** (control plane $2.40, 2x t3.medium $2.00, NAT $1.08,
ALB $0.55). Tear down between sessions.

---

## Conventions

- Terraform config values live in `variables.tf` with defaults, **not** in `.tfvars` —
  `*.tfvars` is gitignored, so anything put there would not be committed.
- `.terraform.lock.hcl` **is** committed.
- Terraform 1.15.8 comes from `hashicorp/tap/terraform`, not homebrew-core.
