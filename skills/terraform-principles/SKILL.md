---
name: terraform-principles
description: "Use when writing, reviewing, or modifying Terraform or OpenTofu code (.tf, .tfvars)"
globs: ["**/*.tf", "**/*.tfvars", "**/*.tofu"]
---

# Terraform Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Modules for Reusability

> Encapsulate repeated infrastructure patterns into versioned, single-purpose modules.

## Rules

- Create modules for common patterns (VPCs, databases, load balancers)
- Keep modules single-purpose and focused
- Use input variables for customization and outputs for composition
- Version modules for stability
- Store modules in separate repositories or directories
- Never copy-paste resource blocks across projects -- extract a module instead

## Example

```hcl
# modules/network/main.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  # ... other configuration
}

output "vpc_id" {
  value = aws_vpc.main.id
}

# main.tf
module "network" {
  source = "./modules/network"

  vpc_cidr = "10.0.0.0/16"
}
```

---

# Use Remote State Backend

> Always store Terraform/OpenTofu state in a remote, encrypted, and locked backend.

## Rules

- Use S3, GCS, Azure Storage, or Terraform Cloud for state storage
- Enable state locking (DynamoDB, GCS, etc.)
- Encrypt state at rest
- Use different backends per environment
- Never commit state files to version control
- Use state backends that support versioning
- When using OpenTofu, prefer client-side state encryption for an additional layer of security

## Example

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

---

# Use Workspaces or Separate Directories for Environments

> Isolate each environment's state and configuration to prevent cross-environment accidents.

## Rules

- Prefer separate directories per environment (recommended for most cases)
- Use Terraform workspaces only for simpler, similar environments
- Use environment-specific variable files
- Use different state backends per environment
- Never share state between environments

## Example

```hcl
# Directory structure
environments/
  production/
    main.tf
    variables.tf
    terraform.tfvars
    backend.tf
  staging/
    main.tf
    variables.tf
    terraform.tfvars
    backend.tf

# Or using workspaces
terraform workspace new production
terraform workspace select production
terraform apply
```

---

# Use Variables and Outputs Effectively

> Define all configurable values as typed, validated, documented variables and expose key attributes as outputs.

## Rules

- Define all configurable values as variables with type constraints and validation
- Provide sensible defaults where appropriate
- Document all variables with descriptions
- Output important resource attributes for module composition
- Never hardcode sensitive values

## Example

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]", var.instance_type))
    error_message = "Instance type must be t2 or t3 family."
  }
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

# outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.main.public_ip
  sensitive   = false
}
```

---

# Use Data Sources for External References

> Query existing resources with data sources instead of hardcoding IDs or ARNs.

## Rules

- Use data sources instead of hardcoding resource IDs
- Query existing resources dynamically
- Use data sources for resources managed outside Terraform
- Leverage data sources for cross-stack references
- Use remote state data sources for module composition

## Example

```hcl
# Get existing VPC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Get AMI dynamically
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

# Reference in resource
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_ubuntu.id
  subnet_id     = data.aws_vpc.existing.default_subnet_id
  instance_type = "t3.micro"
}
```

---

# Use Lifecycle Rules Appropriately

> Control resource creation, replacement, and destruction behavior with lifecycle blocks.

## Rules

- Use `create_before_destroy` for zero-downtime replacements
- Use `prevent_destroy` for critical resources (databases, encryption keys)
- Use `ignore_changes` for attributes managed outside Terraform
- Use `replace_triggered_by` to force replacement on upstream changes
- Document why each lifecycle rule exists

## Example

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false

    ignore_changes = [
      # Tags managed by external system
      tags["ManagedBy"],
      # AMI updates handled separately
      ami,
    ]
  }
}

resource "aws_db_instance" "critical" {
  # ... configuration

  lifecycle {
    prevent_destroy = true  # Never destroy production database
  }
}
```

---

# Use Terraform Cloud, CI/CD, or OpenTofu for Automation

> Automate all Terraform/OpenTofu execution through CI/CD pipelines, Terraform Cloud, or equivalent -- never apply manually.

## Rules

- Use Terraform Cloud/Enterprise, CI/CD pipelines (GitHub Actions, GitLab CI, etc.), or OpenTofu-compatible automation
- Require plan review before apply
- Run `terraform fmt` / `tofu fmt` and `terraform validate` / `tofu validate` in CI
- Use policy as code (Sentinel, OPA) for governance
- Store state remotely and lock during runs
- Never run `terraform apply` or `tofu apply` from a local machine in production

## Example

```yaml
# .github/workflows/terraform.yml — works with both Terraform and OpenTofu
name: Terraform
on:
  pull_request:
    paths:
      - 'terraform/**'
  push:
    branches: [main]
    paths:
      - 'terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      # Use hashicorp/setup-terraform for Terraform
      # or opentofu/setup-opentofu for OpenTofu
      - uses: hashicorp/setup-terraform@v3

      - name: Format Check
        run: terraform fmt -check

      - name: Init
        run: terraform init

      - name: Validate
        run: terraform validate

      - name: Plan
        run: terraform plan

      - name: Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
```

---

# Use Provider Version Constraints

> Pin Terraform/OpenTofu and provider versions to ensure reproducible deployments.

## Rules

- Specify required provider versions in the `required_providers` block
- Use version constraints (e.g., `~> 4.0`, `>= 3.0, < 5.0`)
- Pin the Terraform/OpenTofu version itself in `required_version`
- Commit the `.terraform.lock.hcl` lock file for exact versions
- Test provider upgrades before applying to production
- When using OpenTofu, providers are sourced from the OpenTofu Registry by default -- verify provider availability if migrating

## Example

```hcl
terraform {
  required_version = ">= 1.0, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Allow 4.x but not 5.0
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

---

# Use terraform fmt and validate

> Run `terraform fmt` / `tofu fmt` and `terraform validate` / `tofu validate` on every change, enforced by pre-commit hooks and CI.

## Rules

- Run `terraform fmt -recursive` (or `tofu fmt -recursive`) to format all files consistently
- Run `terraform validate` (or `tofu validate`) to catch syntax and configuration errors early
- Use `terraform fmt -check` (or `tofu fmt -check`) in CI to fail on unformatted code
- Integrate both into pre-commit hooks
- Validate before every commit and in every CI pipeline run
- Both `terraform` and `tofu` CLIs produce compatible formatting -- pick one per project and stay consistent

## Example

```bash
# Format all Terraform/OpenTofu files
terraform fmt -recursive
# or: tofu fmt -recursive

# Check if formatting is needed (for CI)
terraform fmt -check -recursive
# or: tofu fmt -check -recursive

# Validate configuration
terraform validate
# or: tofu validate

# Pre-commit hook example
#!/bin/bash
terraform fmt -check
terraform validate
```

```hcl
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

---

# Use Resource Tags Consistently

> Tag every resource with a standard set of metadata for cost tracking, automation, and governance.

## Rules

- Define a standard tagging strategy and enforce it
- Use a `locals` block or module for common tags
- Always include: Environment, Project, ManagedBy, CostCenter
- Apply tags to all taggable resources
- Use `default_tags` at the provider level when possible
- Merge resource-specific tags with common tags

## Example

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Team        = "Platform"
  }
}

resource "aws_instance" "web" {
  # ... configuration

  tags = merge(
    local.common_tags,
    {
      Name = "web-server-${var.environment}"
      Role = "web"
    }
  )
}

# Provider-level default tags
provider "aws" {
  default_tags {
    tags = local.common_tags
  }
}
```

---

# Use Locals for Computed Values

> Place derived values and complex expressions in `locals` blocks to avoid repetition and improve readability.

## Rules

- Use locals for derived values, transformations, and conditional logic
- Keep complex expressions in locals rather than inline in resources
- Use locals to combine variables into composite values
- Do not use locals as simple aliases for single variables
- Document complex local computations with comments

## Example

```hcl
locals {
  # Combine variables
  full_name = "${var.first_name}-${var.last_name}"

  # Compute CIDR blocks
  subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3),
  ]

  # Conditional values
  instance_count = var.environment == "production" ? 3 : 1

  # Complex transformations
  security_group_rules = [
    for rule in var.custom_rules : {
      type        = rule.type
      from_port   = rule.port
      to_port     = rule.port
      protocol    = rule.protocol
      cidr_blocks = [rule.source_cidr]
    }
  ]
}

resource "aws_instance" "web" {
  count = local.instance_count
  # ... uses local.instance_count
}
```

---

# Use Terraform Workspaces Carefully

> Use workspaces only for similar, short-lived environments; prefer separate directories for production isolation.

## Rules

- Use workspaces for: temporary environments, feature branches, similar environments
- Prefer separate directories for: production vs non-production, significantly different configurations
- Always use workspace-specific variable files or conditionals
- Reference `terraform.workspace` for environment-specific logic
- Be aware that workspaces share the same backend configuration
- Never rely on workspace names as the sole environment differentiator in production

## Example

```hcl
# Use workspace in configuration
locals {
  environment = terraform.workspace
  instance_count = terraform.workspace == "production" ? 3 : 1
}

# Workspace-specific variables
variable "instance_type" {
  default = {
    default    = "t3.micro"
    staging    = "t3.small"
    production = "t3.medium"
  }
}

resource "aws_instance" "web" {
  count         = local.instance_count
  instance_type = var.instance_type[terraform.workspace]

  tags = {
    Environment = terraform.workspace
  }
}
```

---

# Understand and Use Dependency Graphs

> Let Terraform infer dependencies from references; use explicit `depends_on` only when implicit dependencies are insufficient.

## Rules

- Terraform infers dependencies automatically from resource references -- rely on this
- Use `depends_on` explicitly only when there is no reference-based dependency (rare)
- Use `terraform graph` to visualize and debug dependency ordering
- Order resources logically in files for human readability
- Use module outputs to create explicit dependencies between modules
- Never create circular dependencies

## Example

```hcl
# Implicit dependency (Terraform infers this)
resource "aws_security_group" "web" {
  name = "web-sg"
  # ...
}

resource "aws_instance" "web" {
  security_groups = [aws_security_group.web.id]  # Dependency inferred
  # ...
}

# Explicit dependency (when needed)
resource "aws_instance" "web" {
  # ...
  depends_on = [
    aws_iam_role.instance_role,  # Explicit dependency
    aws_cloudwatch_log_group.app  # Explicit dependency
  ]
}

# Module dependency via outputs
module "network" {
  source = "./modules/network"
}

module "compute" {
  source = "./modules/compute"
  vpc_id = module.network.vpc_id  # Creates dependency
}
```

---

# Use OpenTofu-Specific Features When Available

> When using OpenTofu, leverage its unique capabilities for better security, flexibility, and developer experience.

## Rules

- Use client-side state encryption to protect sensitive data at rest -- configure `encryption` blocks in your backend
- Use early variable and local evaluation where supported to simplify configuration
- Source providers from the OpenTofu Registry; verify availability before migrating from Terraform
- Use the `tofu` CLI as a drop-in replacement for `terraform` -- commands and flags are compatible
- Use `-test-directory` flag for running module tests when writing testable infrastructure
- When migrating from Terraform, run `tofu init -upgrade` to re-initialize with OpenTofu-compatible providers
- Keep `required_version` constraints compatible if your team uses both tools

## Example

```hcl
# State encryption (OpenTofu-specific)
terraform {
  encryption {
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.default
    }

    key_provider "pbkdf2" "default" {
      passphrase = var.state_passphrase
    }

    state {
      method   = method.aes_gcm.default
      enforced = true
    }

    plan {
      method   = method.aes_gcm.default
      enforced = true
    }
  }

  backend "s3" {
    bucket         = "my-tofu-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tofu-locks"
  }
}
```

---

# Write Tests for Infrastructure

> Validate Terraform/OpenTofu configurations with automated tests to catch misconfigurations before they reach production.

## Rules

- Use `terraform validate` and `tofu validate` as the first line of defense
- Write policy tests with OPA/Conftest, Sentinel, or Checkov for compliance
- Use `terraform test` (v1.6+) or Terratest for integration testing
- Test modules in isolation with minimal variable inputs
- Validate plan output against expected resources before applying
- Run `terraform plan` in CI on every PR to surface changes early
- Test destructive operations (replacements, deletions) are flagged before apply

## Example

```hcl
# tests/main.tftest.hcl (terraform test)
run "creates_s3_bucket" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.bucket == "my-app-data"
    error_message = "Bucket name must be my-app-data"
  }

  assert {
    condition     = aws_s3_bucket_versioning.main.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled"
  }
}

run "blocks_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true
    error_message = "Public ACLs must be blocked"
  }
}
```

```bash
# Run terraform native tests
terraform test

# Run Checkov for policy compliance
checkov -d .

# Run Conftest with custom OPA policies
conftest test --policy policy/ tfplan.json
```

---

# Follow Security Best Practices

> Harden Terraform/OpenTofu configurations to prevent unauthorized access, data exposure, and insecure infrastructure.

## Rules

- Never store secrets in `.tf` files or `.tfvars`; use environment variables, vault references, or secret manager data sources
- Encrypt state files at rest; use remote backends with encryption (S3 + KMS, GCS + CMEK, OpenTofu state encryption)
- Restrict state file access with IAM policies; state contains sensitive data
- Use `sensitive = true` on variables and outputs that contain secrets
- Enable encryption at rest and in transit for all storage and database resources
- Apply least-privilege IAM policies; never use wildcard (`*`) permissions in production
- Run security scanners (tfsec, Checkov, trivy) in CI to catch misconfigurations

## Example

```hcl
# Bad: secrets in plain text, overly permissive IAM
variable "db_password" {
  default = "hunter2"
}

resource "aws_iam_policy" "admin" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# Good: secrets from vault, least-privilege IAM, encrypted state
variable "db_password" {
  type      = string
  sensitive = true  # Prevents display in logs and plan output
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db/password"
}

resource "aws_iam_policy" "app" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.data.arn}/*"
    }]
  })
}

# Encrypt state with OpenTofu
terraform {
  encryption {
    key_provider "aws_kms" "main" {
      kms_key_id = "alias/tofu-state"
      region     = "us-east-1"
    }
    method "aes_gcm" "main" {
      keys = key_provider.aws_kms.main
    }
    state {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}
```

```bash
# Scan for security issues
tfsec .
checkov -d .
trivy config .
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

For Terraform projects:
- **terraform fmt** — format configuration files: `terraform fmt -recursive`
- **terraform validate** — validate configuration: `terraform validate`
- **tflint** — Terraform linter for best practices: `tflint --recursive`

For OpenTofu projects (use `tofu` instead of `terraform`):
- **tofu fmt** — format configuration files: `tofu fmt -recursive`
- **tofu validate** — validate configuration: `tofu validate`
- **tflint** — linter for best practices (works with both): `tflint --recursive`

Detect which tool the project uses by checking for `.terraform` vs `.tofu` directories, CI config, or lock files. When in doubt, ask the user.

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
