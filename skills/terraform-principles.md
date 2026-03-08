---
name: terraform-principles
description: "Use when writing, reviewing, or modifying Terraform code (.tf, .tfvars)"
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

> Always store Terraform state in a remote, encrypted, and locked backend.

## Rules

- Use S3, GCS, Azure Storage, or Terraform Cloud for state storage
- Enable state locking (DynamoDB, GCS, etc.)
- Encrypt state at rest
- Use different backends per environment
- Never commit state files to version control
- Use state backends that support versioning

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

# Use Terraform Cloud or CI/CD for Automation

> Automate all Terraform execution through CI/CD pipelines or Terraform Cloud -- never apply manually.

## Rules

- Use Terraform Cloud/Enterprise or CI/CD pipelines (GitHub Actions, GitLab CI, etc.)
- Require plan review before apply
- Run `terraform fmt` and `terraform validate` in CI
- Use policy as code (Sentinel, OPA) for governance
- Store state remotely and lock during runs
- Never run `terraform apply` from a local machine in production

## Example

```yaml
# .github/workflows/terraform.yml
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
      - uses: hashicorp/setup-terraform@v1

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
```

---

# Use Provider Version Constraints

> Pin Terraform and provider versions to ensure reproducible deployments.

## Rules

- Specify required provider versions in the `required_providers` block
- Use version constraints (e.g., `~> 4.0`, `>= 3.0, < 5.0`)
- Pin the Terraform version itself in `required_version`
- Commit the `.terraform.lock.hcl` lock file for exact versions
- Test provider upgrades before applying to production

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

> Run `terraform fmt` and `terraform validate` on every change, enforced by pre-commit hooks and CI.

## Rules

- Run `terraform fmt -recursive` to format all files consistently
- Run `terraform validate` to catch syntax and configuration errors early
- Use `terraform fmt -check` in CI to fail on unformatted code
- Integrate both into pre-commit hooks
- Validate before every commit and in every CI pipeline run

## Example

```bash
# Format all Terraform files
terraform fmt -recursive

# Check if formatting is needed (for CI)
terraform fmt -check -recursive

# Validate configuration
terraform validate

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

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **terraform fmt** — format Terraform configuration files: `terraform fmt -recursive`
- **terraform validate** — validate Terraform configuration: `terraform validate`
- **tflint** — Terraform linter for best practices: `tflint --recursive`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
