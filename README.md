# K8S-EKS-Terraform

Production-grade Amazon EKS infrastructure provisioned entirely through Terraform, built as a hands-on learning project with cost optimization as a first-class design constraint at every layer.

**Region:** `ap-south-1` (Mumbai)
**IaC tool:** Terraform `>= 1.16.0`
**State backend:** Amazon S3 + DynamoDB (state locking)

---

## Project goals

- Build a real, secured, production-pattern EKS cluster from first principles — not a quickstart template
- Apply cloud cost optimization at every layer, not as an afterthought
- Practice a repeatable build → test → destroy cycle to avoid idle infrastructure cost during learning
- Eventually wrap the entire provisioning flow in a GitHub Actions CI/CD pipeline (OIDC-based, no static AWS credentials)

---

## Architecture overview

```
AWS Account (ap-south-1)
│
├── Terraform Backend (S3 + DynamoDB)
│     Remote state storage + state locking for every layer below
│
├── VPC (10.0.0.0/16)
│     ├── Public subnets  (3 AZs) → Internet Gateway, NAT Gateway
│     ├── Private subnets (3 AZs) → EKS worker nodes, pods
│     └── S3 Gateway Endpoint (free, no NAT cost for S3 traffic)
│
├── IAM + KMS
│     ├── EKS Cluster Role      (control plane → AWS API access)
│     ├── EKS Node Role         (worker nodes → CNI, ECR, SSM)
│     └── KMS Key               (Kubernetes Secrets envelope encryption)
│
└── EKS Cluster
      ├── Control plane          (private + public endpoint, api+audit logging)
      ├── Core managed node group (Graviton, on-demand, system pods only)
      └── [Planned] Karpenter     (Spot + Graviton autoscaling for workloads)
```

---

## Repository structure

```
K8S-EKS-Terraform/
├── backend-bootstrap/        # One-time manual setup — creates the S3/DynamoDB backend
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
│
├── modules/                  # Reusable resource blueprints — never hold env-specific values
│   ├── vpc/
│   ├── kms/
│   ├── iam/
│   └── eks/
│
└── envs/
    └── dev/                  # Environment-specific wiring — calls modules with dev values
        ├── vpc/
        ├── kms/
        ├── iam/
        └── eks/
```

**Convention:** every `envs/<env>/<service>/` folder is a thin wrapper — `main.tf` just calls the matching module, `terraform.tfvars` holds the actual values, and `backend.tf` points to the shared S3/DynamoDB state. Resource logic lives only inside `modules/`, so adding a new environment (`envs/prod/`) means copying the wrapper files and changing values — never touching module internals.

---

## Components built so far

| Layer | Status | What it does |
|---|---|---|
| Backend bootstrap | ✅ Built (destroyed after each session) | S3 state storage + DynamoDB state locking |
| VPC | ✅ Built | 3 public + 3 private subnets, single NAT, IGW, S3 endpoint |
| IAM + KMS | ✅ Built | Cluster/node IAM roles, least-privilege policies, KMS key for secrets encryption |
| EKS cluster | ✅ Built and verified | Control plane + Graviton core node group, `kubectl` verified working |
| Karpenter | 🔜 Next | Spot + Graviton autoscaling for actual workloads |
| Add-ons (ALB Controller, CSI drivers) | 🔜 Planned | Ingress, storage |
| Security hardening (Kyverno, GuardDuty) | 🔜 Planned | Admission control, threat detection |
| CI/CD (GitHub Actions) | 🔜 Planned | OIDC-based automated provisioning |

---

## Cost optimization decisions

Every layer applies a specific cost lever rather than defaulting to AWS's most expensive option:

| Decision | Saving |
|---|---|
| Single shared NAT Gateway (`single_nat_gateway = true`) instead of one per AZ | ~$60–65/month in dev |
| S3 Gateway Endpoint (free) instead of routing S3 traffic through NAT | Removes NAT data-processing charges for S3 traffic |
| Graviton (`AL2_ARM_64`, `t4g.medium`) instead of x86 | ~20% cheaper compute for equivalent performance |
| DynamoDB `PAY_PER_REQUEST` billing for state locking | Near-zero cost for infrequent applies |
| Selective control-plane logging (`api`, `audit` only, not all 5 types) | Reduced CloudWatch ingestion cost |
| SSM Session Manager instead of a bastion host | Removes an always-on EC2 cost and an open attack surface |
| **Destroy compute after every learning session, keep only the backend** | Removes the EKS control plane's flat ~$0.10/hr charge when not actively in use |

---

## Prerequisites

Installed via Chocolatey on Windows (Git Bash for daily use):

```bash
aws --version                    # AWS CLI v2
terraform -version               # Terraform >= 1.16.0
kubectl version --client         # kubectl
helm version                     # Helm
eksctl version                   # eksctl
k9s version                      # k9s
session-manager-plugin           # SSM plugin (no --version flag; run bare to confirm)
```

AWS CLI configured with a region of `ap-south-1` and credentials with sufficient permissions to manage VPC, IAM, KMS, and EKS resources.

---

## Usage

### First-time setup (per AWS account)

```bash
cd backend-bootstrap
terraform init
terraform apply
```

Note the `state_bucket_name` and `lock_table_name` outputs — every other layer's `backend.tf` references these.

### Build order (each layer depends on the previous)

```bash
cd envs/dev/vpc   && terraform init && terraform apply
cd envs/dev/kms   && terraform init && terraform apply
cd envs/dev/iam   && terraform init && terraform apply
cd envs/dev/eks   && terraform init && terraform apply
```

EKS cluster creation takes approximately 15–20 minutes end to end (control plane + node group).

### Connect kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name nr-jerney-dev
kubectl get nodes
kubectl get pods -A
```

### Destroy (reverse order — cost-saving teardown)

```bash
cd envs/dev/eks   && terraform destroy
cd ../iam         && terraform destroy
cd ../kms         && terraform destroy
cd ../vpc         && terraform destroy
```

**Do not destroy `backend-bootstrap`** unless intentionally starting over — it holds all Terraform state history and costs negligibly to keep running.

---

## Naming conventions

- All AWS resources prefixed `nr-` (personal identifier)
- Pattern: `nr-<project>-<environment>-<resource>` (e.g. `nr-k8s-eks-dev-eks-cluster-role`)
- `for_each` used over `count` for all resources with identity (AZs, subnets) to avoid index-shift destroy/recreate issues

---

## Roadmap

1. Karpenter — Spot + Graviton workload autoscaling
2. AWS Load Balancer Controller + EBS CSI driver (Helm-based add-ons)
3. Security hardening — Kyverno/OPA Gatekeeper, GuardDuty EKS Protection, External Secrets Operator
4. Observability — CloudWatch Container Insights, later Prometheus + Grafana
5. GitHub Actions CI/CD pipeline — OIDC authentication, plan-on-PR / apply-on-merge
6. `envs/prod/` — high-availability variant (multi-NAT, restricted public access CIDR)

---

## Author

Built and maintained as a hands-on DevOps/Cloud learning project, focused on production-realistic patterns and continuous cost-awareness.
