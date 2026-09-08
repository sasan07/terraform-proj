# Terraform AWS Infrastructure — Multi-Environment EC2 + S3 with CI Validation

A Terraform project provisioning an EC2 web server and an S3 bucket on AWS, parameterized for separate **dev** and **prod** environments, with GitHub Actions running automated `plan` validation on every push.

## Overview

This project provisions:
- A single **EC2 instance** running as a web server, secured by a dedicated security group
- An **S3 bucket** tagged per environment
- Environment-specific configuration via separate `dev.tfvars` and `prod.tfvars` files, so the same Terraform code can stand up either environment without modification

A **GitHub Actions** workflow automatically validates the Terraform configuration on every push to `master`.

## Tech Stack

| Layer                   | Tool / Technology              |
|--------------------------|----------------------------------|
| Infrastructure as Code   | Terraform (AWS provider)         |
| CI                        | GitHub Actions                   |
| Cloud Provider            | AWS (EC2, S3, Security Groups)   |
| Environment Management    | `.tfvars` per environment (dev/prod) |

## Repository Structure

```
terraform-project/
├── .github/
│   └── workflows/
│       └── terraform.yml     # CI: init, validate, plan on push to master
├── ec2.tf                    # EC2 instance resource
├── s3.tf                     # S3 bucket resource
├── sg.tf                     # Security group (SSH + HTTP)
├── provider.tf                # AWS provider config
├── variable.tf                 # Variable declarations
├── output.tf                   # Outputs: instance public IP, bucket name
├── dev.tfvars                  # Dev environment values
├── prod.tfvars                 # Prod environment values
└── .gitignore
```

## Infrastructure Components

**EC2 (`ec2.tf`)** — provisions a single `aws_instance.web` using a configurable AMI and instance type, attached to the project's security group, tagged with its environment.

**S3 (`s3.tf`)** — provisions `aws_s3_bucket.demo` with an environment-specific bucket name and tags.

**Security Group (`sg.tf`)** — named per environment (`${var.environment}-web_sg`), allowing inbound:
- Port `22` (SSH)
- Port `80` (HTTP)
- All outbound traffic

**Outputs (`output.tf`)**
- `instance_public_ip` — the EC2 instance's public IP
- `aws_s3_bucket` — the provisioned bucket's name

## Variables

| Variable          | Description                          |
|--------------------|----------------------------------------|
| `aws_region`        | AWS region to deploy into              |
| `instance_type`      | EC2 instance type (e.g., `t3.micro`)   |
| `instance_name`      | Intended display name for the instance |
| `ami_id`             | AMI ID for the EC2 instance             |
| `bucket_name`        | S3 bucket name (must be globally unique)|
| `environment`        | Environment label (`dev` / `prod`), used in tags and the security group name |

## Environments

| Environment | Var File        | Bucket Name              | Instance Label |
|--------------|-------------------|-----------------------------|-----------------|
| Dev          | `dev.tfvars`        | `my-devsingh-bucket-124`     | `Dev-server`     |
| Prod         | `prod.tfvars`       | `my-prod-singh-4347`         | `Prod-server`    |

Both environments share the same Terraform code — only the variable values differ, keeping infrastructure consistent across environments.

## CI/CD — GitHub Actions

`.github/workflows/terraform.yml` runs on every push to `master`:

1. Checks out the repository
2. Sets up Terraform (`hashicorp/setup-terraform`)
3. Configures AWS credentials from GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
4. Runs `terraform init`
5. Runs `terraform validate`
6. Runs `terraform plan -var-file="dev.tfvars"`

This gives automated syntax/config validation and a plan preview on every push — it currently validates against the **dev** environment only and does not run `terraform apply` (deployment is manual).

## Setup & Usage

1. Configure AWS credentials locally (or via GitHub Secrets for CI).
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Plan against the desired environment:
   ```bash
   terraform plan -var-file="dev.tfvars"
   # or
   terraform plan -var-file="prod.tfvars"
   ```
4. Apply:
   ```bash
   terraform apply -var-file="dev.tfvars"
   ```
5. Retrieve outputs:
   ```bash
   terraform output
   ```

## Known Limitations / Next Steps

- `instance_name` is declared and populated in both `.tfvars` files but isn't currently applied to the EC2 resource's `Name` tag in `ec2.tf` — a fix would wire `var.instance_name` into the tag block.
- The GitHub Actions workflow always plans against `dev.tfvars`, regardless of branch — a natural next step would be branch-based logic (e.g., `develop` → dev plan, `master` → prod plan) or a manual `workflow_dispatch` input to select environment.
- The workflow stops at `plan`; adding a gated `apply` step (with manual approval for prod) would complete the pipeline.
- The security group opens SSH (port 22) to `0.0.0.0/0` — fine for a learning/demo environment, but in production this should be restricted to a known IP range or accessed via a bastion host / SSM Session Manager instead.

## Key Outcomes

- Built a reusable, environment-parameterized Terraform configuration for AWS infrastructure
- Implemented automated CI validation (`init`, `validate`, `plan`) via GitHub Actions on every push
- Established a dev/prod separation pattern using `.tfvars`, a standard approach for managing multiple environments from a single codebase
