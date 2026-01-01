# Installation Guide

This document describes the **installation workflow only**.

For architecture, design decisions, scope, and responsibility split, see  
**[`README.md`](/README.md) in the repository root**.

This file intentionally avoids infrastructure explanations and design rationale.
It focuses solely on **what must be done, in what order, and where**.

---

## 0. Repository context

Clone the infrastructure repository locally:

```bash
git clone https://github.com/LaurisNeimanis/aws-eks-platform.git
cd aws-eks-platform
```

All subsequent commands assume execution from the repository root.

---

## 1. Prerequisites

### Local tooling

* Terraform **~> 1.14**
* AWS CLI v2
* kubectl (matching EKS version)

### AWS

* An AWS account with permissions for:

  * EKS, EC2, VPC, IAM, KMS, CloudWatch
  * S3 + DynamoDB (Terraform backend)

---

## 2. External dependency — Terraform backend (mandatory, one-time per account)

This repository **does not create** the Terraform backend.

Before running anything here, you must bootstrap the backend using the
dedicated repository:

**Authoritative backend bootstrap:**  
https://github.com/LaurisNeimanis/aws-tf-backend-bootstrap

That repository must be applied **once per AWS account** and creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

After that:
- This repository only consumes the backend

### Backend configuration (required)

You **must explicitly configure** the backend for your account.

Update the backend definition in:

- `terraform/global/acm/backend.tf`
- `terraform/envs/dev/backend.tf`

with:
- your S3 bucket name
- your DynamoDB lock table name
- correct region and state key

before running `terraform init`.

This repository assumes a **pre-existing backend** and will not
initialize or modify it.

---

## 3. Global scope: ACM (Cloudflare DNS validation)

This step must be completed **before** any ingress or ALB-based workloads.

### Configuration

Create the real tfvars file from the example:

```bash
cd terraform/global/acm

cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set real values:
- `cloudflare_zone_id`
- `primary_domain`
- `san_domains`

Provide Cloudflare API token via environment variable:

```bash
export TF_VAR_cloudflare_api_token=xxxxxxxx
```

Apply:

```bash
terraform init
terraform apply
```

---

## 4. Environment scope: EKS (dev example)

### Configuration

Create tfvars from example if not already present:

```bash
cd terraform/envs/dev

cp terraform.tfvars.example terraform.tfvars
```

Adjust values as needed:
- region
- CIDRs
- node instance types
- API endpoint CIDR allowlist
- Kubernetes version

Apply:

```bash
terraform init
terraform apply
```

---

## 5. Authentication model (behavioral notes)

* **authentication_mode = API**
* `aws-auth` ConfigMap is **not used**
* Access is managed via **EKS Access Entries**
* In **dev only**: cluster creator gets admin automatically
* In stage/prod: access must be explicitly defined

---

## 6. Cluster access

After successful apply:

```bash
aws eks update-kubeconfig --region eu-central-1 --name eks-platform-dev-cluster
```

Verify:

```bash
kubectl get nodes
kubectl get pods -A
```

---

## 7. What this installation does NOT include

This repository stops at infrastructure.

It does NOT install:
- GitOps tooling (ArgoCD)
- Ingress controllers
- Observability stack
- Workloads or applications

Those are handled by higher-level repositories.

---

## 8. Environment expansion

To add `stage` or `prod`:
- Copy `terraform/envs/dev`
- Adjust backend key and tfvars
- Apply independently

Do not reuse state keys between environments.
