# AWS EKS Terraform Platform — Infrastructure Foundation

**Production-aligned · API-Only Authentication · Cloudflare-Integrated · GitOps-Ready**

This repository implements a **production-aligned AWS infrastructure foundation** for running Kubernetes workloads on **Amazon EKS**, provisioned entirely via **Terraform**.

It provides a **clean, explicit, and auditable infrastructure layer** designed to be consumed by a **separate GitOps / workload lifecycle repository**, mirroring how modern platform teams split responsibilities in real production environments.

This repository is the **authoritative source of truth for AWS infrastructure**.

---

## Installation

This repository does not include a quick-start guide.

For the exact installation order, required configuration files,
and Terraform execution steps, see:

➡️ **[`install.md`](install.md)**

---

## Purpose & Scope

The goal of this repository is to deliver a **stable, minimal, and extensible EKS foundation**, not a demo cluster.

It focuses on:

- Correct AWS primitives
- Explicit authentication and access model
- Deterministic networking and security boundaries
- Automation-first certificate and DNS handling
- Clear dev → prod evolution path

Everything **above the cluster** (platform services, workloads, GitOps logic) is intentionally **out of scope**.

---

## Minimum platform requirements

This platform is production-aligned by design, but can be provisioned
and validated in a minimal non-production setup.

### Baseline (dev / non-production)

The following baseline has been validated to successfully provision
the infrastructure layer defined in this repository:

- **EKS managed node groups**
  - Instance types: `t4g.micro` (AWS Graviton, ARM64)
  - Architecture: **ARM64**
  - AMI: **Amazon Linux 2023 (ARM)**
  - Node count: **2**
- **Cluster capacity**
  - Sufficient for core control-plane addons:
    - CoreDNS
    - VPC CNI
    - metrics-server
  - Suitable for infrastructure validation and GitOps bootstrap
  - This baseline assumes no additional platform workloads beyond core addons
    and requires all workloads and addons to support **linux/arm64**.

This baseline is intended for **development and validation purposes only**.

### Notes and limitations

- Smaller node counts or single-node clusters may fail during:
  - addon scheduling
  - rolling updates
  - node replacement events
- Production environments typically require:
  - larger instance sizes
  - multiple node groups
  - higher fault tolerance and scaling policies

Production sizing is intentionally environment-specific and
explicitly out of scope for this repository.

---

## Architectural Principles

The infrastructure design prioritizes:

- Explicit ownership of infrastructure lifecycle
- IAM-native, API-only Kubernetes authentication
- Minimal moving parts at the infrastructure layer
- Separation of infrastructure and cluster lifecycle concerns
- Cost-aware defaults without compromising production parity

The result is an infrastructure layer that is **boring, predictable, and safe** — by design.

---

## Terraform Backend Bootstrap

This infrastructure uses a **pre-bootstrapped, shared Terraform backend** based on **S3 + DynamoDB**, created and managed via a **dedicated bootstrap repository**.

**Terraform backend bootstrap (authoritative):**  
https://github.com/LaurisNeimanis/aws-tf-backend-bootstrap

That repository is responsible for **one-time creation** of:

- A globally unique S3 bucket for Terraform state
- A DynamoDB table for state locking
- Versioning, encryption, and public access blocking

The backend is shared across all Terraform scopes and environments by design.

This repository **does not create or modify backend infrastructure** — it only consumes it.

---

## Core Technologies (Actual Implementation)

- **AWS VPC** — `terraform-aws-modules/vpc` v6  
- **Amazon EKS** — `terraform-aws-modules/eks` v21  
- **EKS Managed Node Groups** (Amazon Linux 2023 · ARM64 / AWS Graviton)
- **EKS Access API** (API-only authentication mode)  
- **AWS ACM** — DNS-validated certificates  
- **Cloudflare DNS** — automated ACM validation records  
- **S3 Gateway VPC Endpoint**  
- **S3 + DynamoDB** remote Terraform backend (bootstrapped externally)  
- **Cost-optimized NAT** (single NAT for non-production environments)

No legacy components. No implicit defaults.

---

## Responsibility Split

### In scope

- Environment-scoped AWS infrastructure (VPC, EKS, networking)
- IAM roles and access model
- Global ACM certificate lifecycle
- Cloudflare DNS automation for certificate validation
- Terraform state consumption and locking

### Out of scope

- Terraform backend creation (S3, DynamoDB)
- Kubernetes workloads
- GitOps tooling (ArgoCD, ApplicationSets)
- Ingress controllers
- DNS routing for applications
- CI/CD pipelines
- Runtime secrets

Related repositories:

- **Terraform backend bootstrap:** https://github.com/LaurisNeimanis/aws-tf-backend-bootstrap  
- **GitOps layer:** https://github.com/LaurisNeimanis/aws-eks-gitops

---

## Repository Structure

```text
terraform/
├── envs/
│   └── dev/        # Environment-scoped infrastructure (VPC, EKS)
│
├── global/
│   └── acm/        # Global ACM certificates + Cloudflare DNS validation
│
└── modules/
    └── acm-cloudflare/  # Reusable ACM + Cloudflare integration module
```

Each environment is **logically self-contained** and independently deployable,
while relying on a **shared, pre-created Terraform backend** for state storage and locking.

- `envs/*` manage **environment-scoped infrastructure** (VPC, EKS, networking).
- `global/*` manage **account-wide or shared resources** (ACM certificates, DNS automation).
- `modules/*` contain **reusable, isolated Terraform building blocks**.

---

## Architecture Overview

```mermaid
flowchart TB
  Operator["Operator / CI<br/>(Terraform)"]

  subgraph TF["Terraform Scopes"]
    Global["Global Scope<br/>(ACM + DNS)"]
    Env["Env Scope<br/>(VPC + EKS)"]
  end

  TFSTATE["Terraform Backend<br/>(State + Locking)"]

  subgraph AWS["AWS Account"]
    VPC["VPC"]
    EKS["Amazon EKS"]
    ACM["AWS ACM"]
  end

  CF["Cloudflare DNS"]

  Operator --> TFSTATE
  Operator --> Global
  Operator --> Env

  Env --> VPC
  Env --> EKS
  EKS --> VPC

  Global --> ACM
  ACM --> CF
```

> This is a high-level platform overview.  
>  
> A detailed infrastructure and networking diagram is available here:  
> **[docs/architecture.mmd](docs/architecture.mmd)**

---

## Terraform Workflow

Infrastructure is applied per-scope and per-environment
using standard Terraform workflows.

For the exact installation order, configuration files,
and commands, see:

**[`install.md`](install.md)**

---

## Terraform CI (Quality Gates)

This repository includes a **GitHub Actions–based Terraform CI pipeline** that enforces
**formatting, linting, security scanning, and validation** on all Terraform changes.

The CI pipeline is **not a delivery mechanism**.

It exists solely to ensure that:

- Terraform code remains syntactically valid
- Formatting is consistent and deterministic
- Common misconfigurations are caught early
- Security issues are flagged before merge
- Infrastructure definitions stay reviewable and safe

### What the CI does

On every pull request and on pushes to `main` (Terraform paths only), the pipeline runs:

- `terraform fmt -check` (repo-wide)
- `terraform init` (without backend, CI-safe)
- `terraform validate`
- `tflint` (static analysis)
- `tfsec` (security scanning)

A minimal `terraform.tfvars` is provisioned automatically in CI using
`terraform.tfvars.example` to allow validation without secrets.

### What the CI does NOT do

- No `terraform plan`
- No `terraform apply`
- No backend access
- No environment mutation

All infrastructure changes are still applied **manually or via controlled pipelines**
outside of this repository.

This keeps the infrastructure layer **safe, auditable, and review-driven**.

---

## Design Summary

This repository provides a **clean, production-aligned EKS infrastructure foundation** with:

- IAM-native, API-only authentication
- Explicit networking and security boundaries
- Fully automated ACM + Cloudflare integration
- Shared, pre-bootstrapped Terraform backend
- Deterministic Terraform workflows
- Clear separation from GitOps and workload concerns

It is intentionally designed to be **boring infrastructure** — so higher layers can evolve safely.
