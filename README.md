# Agentic Principles

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Curated coding principles that AI agents and developers actually follow.** Distributed as Claude Code skills that activate automatically based on the files you are working with.

Agentic Principles ships 175+ actionable rules across 12 technology categories. Install the skills into any Claude Code project and they load on demand -- no configuration, no hooks, no bootstrap scripts.

## Why?

AI coding agents are powerful, but they need guardrails. Style guides rot in wikis. Linter configs drift across repos. Agentic Principles solves this by:

- **Context-triggered** -- skills activate automatically when you touch relevant file types
- **Always loading** security principles -- because every project needs them
- **Including linting guidance** -- each skill tells the agent which formatters and linters to run
- **Staying current** -- update skills by pulling the latest from the repo
- **Zero config** -- no hooks, no install scripts, no settings merge

## Quick Start

### One-line install

**Global install (all projects):**

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --global
```

**Local install (this project only):**

```bash
cd /path/to/your/project
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --local
```

**Update:**

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --update
```

**Uninstall:**

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --uninstall
```

Updates are checked automatically once per day on session start. When an update is available, Claude will notify you.

### Manual install

Alternatively, install the skill files manually:

```bash
# Clone the repo
git clone https://github.com/asciifylabs/agentic-principles.git /tmp/agentic-principles

# Copy skills into your project
mkdir -p .claude/skills
cp /tmp/agentic-principles/skills/*.md .claude/skills/
```

Or fetch individual skills directly:

```bash
mkdir -p .claude/skills

# Example: install only the skills you need
curl -sO --output-dir .claude/skills \
  https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/skills/security-principles.md

curl -sO --output-dir .claude/skills \
  https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/skills/python-principles.md
```

That's it. Claude Code reads skill files from `.claude/skills/` and activates them based on context.

## Table of Contents

- [Available Skills](#available-skills)
- [Supported Technologies](#supported-technologies)
- [Principles Reference](#principles-reference)
- [Building Skills](#building-skills)
- [Contributing](#contributing)
- [License](#license)

## Available Skills

Each skill is a self-contained Markdown file with YAML frontmatter that tells Claude Code when to activate it:

| Skill File | Activates When |
| --- | --- |
| `security-principles.md` | Writing, reviewing, or modifying any code in any language |
| `docker-principles.md` | Working with Dockerfiles, docker-compose files, or container configurations |
| `shell-principles.md` | Working with `.sh`, `.bash`, Makefile, or Dockerfile |
| `go-principles.md` | Working with `.go`, `go.mod`, `go.sum` |
| `python-principles.md` | Working with `.py`, `pyproject.toml`, `requirements.txt` |
| `nodejs-principles.md` | Working with `.js`, `.ts`, `.tsx`, `package.json` |
| `rust-principles.md` | Working with `.rs`, `Cargo.toml` |
| `terraform-principles.md` | Working with `.tf`, `.tfvars` |
| `ansible-principles.md` | Working with playbooks, roles, `ansible.cfg` |
| `kubernetes-principles.md` | Working with Kubernetes manifests or Helm charts |
| `git-principles.md` | Creating git commits, writing commit messages, or performing git operations |
| `ai-principles.md` | Working with AI/ML frameworks (OpenAI, Anthropic, LangChain, PyTorch, TensorFlow) |

## Supported Technologies

### Git -- 7 principles

Commit hygiene, conventional commits, atomic changes, branch workflow, secret prevention, and pre-commit review discipline.

### Security -- 18 principles (always loaded)

Language-agnostic security and code quality standards covering OWASP top 10, secrets management, input validation, authentication, authorization, XSS/CSRF prevention, secure defaults, and more.

### Docker -- 15 principles

Multi-stage builds, non-root users, image pinning, `.dockerignore`, layer optimization, health checks, secrets management, read-only filesystems, vulnerability scanning, capability dropping, minimal base images, exec form entrypoints, seccomp/AppArmor, and BuildKit features.

### Shell -- 12 principles

`set -euo pipefail`, quoting, error handling, temporary files, structured logging, arrays, and functions.

### Terraform -- 13 principles

Modules, remote state, workspaces, lifecycle rules, provider constraints, dependency graphs, and tagging.

### Ansible -- 12 principles

Roles, idempotency, handlers, templates, tags, facts, vault, inventories, and conditionals.

### Kubernetes -- 18 principles

Namespaces, resource limits, probes, RBAC, network policies, pod security, priority classes, plus Cilium-specific networking (routing, Hubble, eBPF, bandwidth manager).

### Node.js -- 15 principles

Async/await, error handling, ESM modules, dependency locking, structured logging, TypeScript, graceful shutdown, and project structure.

### Python -- 25 principles

Type hints, context managers, PEP 8, virtual environments, dataclasses, pytest, async I/O, plus AI development principles (API keys, rate limits, streaming, prompt engineering, vector DBs, caching).

### Go -- 20 principles

Error handling, interfaces, context, channels, goroutine leaks, defer, struct embedding, project layout, build tags, and benchmarks.

### AI -- 28 principles

Prompt engineering, output validation, RAG pipelines, chunking strategies, LLM observability, failure handling, context window management, guardrails, evaluation, token optimization, caching, streaming, function calling, agent loops, model selection, embeddings, hybrid search, model versioning, bias detection, human-in-the-loop, API security, testing, training data quality, multi-agent systems, few-shot examples, prompt injection prevention, and multimodal input handling.

### Rust -- 20 principles

Ownership, Result/Option, traits, cargo, clippy, pattern matching, smart pointers, async/await, error types, lifetimes, and zero-cost abstractions.

## Principles Reference

<details>
<summary><strong>Git</strong> -- 7 principles</summary>

| #   | Principle                                                                    |
| --- | ---------------------------------------------------------------------------- |
| 001 | [Never Add AI Co-Authorship](git/001-never-add-ai-coauthorship.md)           |
| 002 | [Pull and Rebase Before Committing](git/002-pull-and-rebase-before-committing.md) |
| 003 | [Write Conventional Commit Messages](git/003-write-conventional-commits.md)  |
| 004 | [Commit Atomic Changes](git/004-commit-atomic-changes.md)                    |
| 005 | [Use Branches for Features](git/005-use-branches-for-features.md)            |
| 006 | [Never Commit Secrets](git/006-never-commit-secrets.md)                      |
| 007 | [Review Changes Before Committing](git/007-review-before-committing.md)      |

</details>

<details>
<summary><strong>Security</strong> -- 18 principles</summary>

| #   | Principle                                                                                              |
| --- | ------------------------------------------------------------------------------------------------------ |
| 001 | [Never Hardcode Secrets](security/001-never-hardcode-secrets.md)                                       |
| 002 | [Validate and Sanitize All Inputs](security/002-validate-and-sanitize-inputs.md)                       |
| 003 | [Use Parameterized Queries](security/003-use-parameterized-queries.md)                                 |
| 004 | [Prevent Cross-Site Scripting (XSS)](security/004-prevent-cross-site-scripting.md)                     |
| 005 | [Implement Authentication Properly](security/005-implement-authentication-properly.md)                 |
| 006 | [Enforce Authorization and Least Privilege](security/006-enforce-authorization-and-least-privilege.md) |
| 007 | [Protect Against CSRF](security/007-protect-against-csrf.md)                                           |
| 008 | [Use HTTPS and Secure Communication](security/008-use-https-and-secure-communication.md)               |
| 009 | [Handle Errors Without Leaking Information](security/009-handle-errors-without-leaking-information.md) |
| 010 | [Log Security Events](security/010-log-security-events.md)                                             |
| 011 | [Keep Dependencies Secure](security/011-keep-dependencies-secure.md)                                   |
| 012 | [Use Secure Defaults](security/012-use-secure-defaults.md)                                             |
| 013 | [Protect Sensitive Data](security/013-protect-sensitive-data.md)                                       |
| 014 | [Prevent Injection Attacks](security/014-prevent-injection-attacks.md)                                 |
| 015 | [Implement Rate Limiting](security/015-implement-rate-limiting.md)                                     |
| 016 | [Use Static Analysis and Linting](security/016-use-static-analysis-and-linting.md)                     |
| 017 | [Write Security-Focused Tests](security/017-write-security-focused-tests.md)                           |
| 018 | [Follow Secure Code Review Practices](security/018-follow-secure-code-review-practices.md)             |

</details>

<details>
<summary><strong>Docker</strong> -- 15 principles</summary>

| #   | Principle                                                                                      |
| --- | ---------------------------------------------------------------------------------------------- |
| 001 | [Use Specific Image Tags](docker/001-use-specific-image-tags.md)                               |
| 002 | [Use Multi-Stage Builds](docker/002-use-multi-stage-builds.md)                                 |
| 003 | [Run as Non-Root User](docker/003-run-as-non-root.md)                                          |
| 004 | [Use .dockerignore](docker/004-use-dockerignore.md)                                            |
| 005 | [Minimize Layers and Image Size](docker/005-minimize-layers.md)                                |
| 006 | [Use COPY Instead of ADD](docker/006-use-copy-not-add.md)                                      |
| 007 | [Set Health Checks](docker/007-set-health-checks.md)                                           |
| 008 | [Never Store Secrets in Images](docker/008-never-store-secrets-in-images.md)                    |
| 009 | [Use Read-Only Filesystem](docker/009-use-read-only-filesystem.md)                              |
| 010 | [Scan Images for Vulnerabilities](docker/010-scan-images-for-vulnerabilities.md)                |
| 011 | [Drop All Capabilities](docker/011-drop-capabilities.md)                                       |
| 012 | [Use Minimal Base Images](docker/012-use-minimal-base-images.md)                                |
| 013 | [Use Exec Form for CMD and ENTRYPOINT](docker/013-use-exec-form-for-entrypoint.md)              |
| 014 | [Set Security Options](docker/014-set-security-options.md)                                      |
| 015 | [Use BuildKit Features](docker/015-use-buildkit-features.md)                                    |

</details>

<details>
<summary><strong>Shell</strong> -- 12 principles</summary>

| #   | Principle                                                                    |
| --- | ---------------------------------------------------------------------------- |
| 001 | [Use `set -euo pipefail`](shell/001-use-set-euo-pipefail.md)                 |
| 002 | [Use Functions for Reusability](shell/002-use-functions-for-reusability.md)  |
| 003 | [Proper Error Handling](shell/003-proper-error-handling.md)                  |
| 004 | [Always Quote Variables](shell/004-quote-variables.md)                       |
| 005 | [Use Local Variables in Functions](shell/005-use-local-variables.md)         |
| 006 | [Validate All Inputs](shell/006-validate-inputs.md)                          |
| 007 | [Use Temporary Files Safely](shell/007-use-temporary-files-safely.md)        |
| 008 | [Structured Logging](shell/008-logging-best-practices.md)                    |
| 009 | [Avoid Hardcoded Paths](shell/009-avoid-hardcoded-paths.md)                  |
| 010 | [Use Here Documents](shell/010-use-here-documents.md)                        |
| 011 | [Check Command Existence](shell/011-check-command-existence.md)              |
| 012 | [Use Arrays for Multiple Values](shell/012-use-array-for-multiple-values.md) |

</details>

<details>
<summary><strong>Terraform</strong> -- 13 principles</summary>

| #   | Principle                                                                                         |
| --- | ------------------------------------------------------------------------------------------------- |
| 001 | [Use Modules for Reusability](terraform/001-use-modules-for-reusability.md)                       |
| 002 | [Use Remote State](terraform/002-use-remote-state.md)                                             |
| 003 | [Use Workspaces or Separate Directories](terraform/003-use-workspaces-or-separate-directories.md) |
| 004 | [Use Variables and Outputs](terraform/004-use-variables-and-outputs.md)                           |
| 005 | [Use Data Sources](terraform/005-use-data-sources.md)                                             |
| 006 | [Use Lifecycle Rules](terraform/006-use-lifecycle-rules.md)                                       |
| 007 | [Use Terraform Cloud or CI/CD](terraform/007-use-terraform-cloud-or-ci-cd.md)                     |
| 008 | [Use Provider Version Constraints](terraform/008-use-provider-version-constraints.md)             |
| 009 | [Use `terraform fmt` and `validate`](terraform/009-use-terraform-fmt-and-validate.md)             |
| 010 | [Use Resource Tags](terraform/010-use-resource-tags.md)                                           |
| 011 | [Use Locals for Computed Values](terraform/011-use-locals-for-computed-values.md)                 |
| 012 | [Use Workspaces Carefully](terraform/012-use-terraform-workspaces-carefully.md)                   |
| 013 | [Understand Dependency Graphs](terraform/013-use-dependency-graphs.md)                            |

</details>

<details>
<summary><strong>Ansible</strong> -- 12 principles</summary>

| #   | Principle                                                                           |
| --- | ----------------------------------------------------------------------------------- |
| 001 | [Use Roles Over Playbooks](ansible/001-use-roles-over-playbooks.md)                 |
| 002 | [Write Idempotent Tasks](ansible/002-use-idempotent-tasks.md)                       |
| 003 | [Use Variables and Defaults](ansible/003-use-variables-and-defaults.md)             |
| 004 | [Use Handlers for Notifications](ansible/004-use-handlers-for-notifications.md)     |
| 005 | [Use Templates Over Static Files](ansible/005-use-templates-over-static-files.md)   |
| 006 | [Use Tags for Selective Execution](ansible/006-use-tags-for-selective-execution.md) |
| 007 | [Use Facts Wisely](ansible/007-use-facts-wisely.md)                                 |
| 008 | [Use Blocks for Error Handling](ansible/008-use-blocks-for-error-handling.md)       |
| 009 | [Use Vault for Secrets](ansible/009-use-vault-for-secrets.md)                       |
| 010 | [Use Inventories Effectively](ansible/010-use-inventories-effectively.md)           |
| 011 | [Use Conditional Logic](ansible/011-use-conditional-logic.md)                       |
| 012 | [Use Loops Efficiently](ansible/012-use-loops-efficiently.md)                       |

</details>

<details>
<summary><strong>Kubernetes</strong> -- 18 principles</summary>

**General**

| #   | Principle                                                                                            |
| --- | ---------------------------------------------------------------------------------------------------- |
| 001 | [Use Namespaces for Isolation](kubernetes/001-use-namespaces-for-isolation.md)                       |
| 002 | [Set Resource Requests and Limits](kubernetes/002-set-resource-requests-and-limits.md)               |
| 003 | [Use Liveness and Readiness Probes](kubernetes/003-use-liveness-and-readiness-probes.md)             |
| 004 | [Use ConfigMaps and Secrets Properly](kubernetes/004-use-configmaps-and-secrets-properly.md)         |
| 005 | [Use Labels and Annotations Consistently](kubernetes/005-use-labels-and-annotations-consistently.md) |
| 006 | [Use PodDisruptionBudgets](kubernetes/006-use-poddisruptionbudgets.md)                               |
| 007 | [Use Network Policies](kubernetes/007-use-network-policies.md)                                       |
| 008 | [Use RBAC Properly](kubernetes/008-use-rbac-properly.md)                                             |
| 009 | [Use Pod Security Standards](kubernetes/009-use-pod-security-standards.md)                           |
| 010 | [Use Priority Classes](kubernetes/010-use-priority-classes.md)                                       |

**Cilium Networking**

| #   | Principle                                                                               |
| --- | --------------------------------------------------------------------------------------- |
| 011 | [Choose the Right Routing Mode](kubernetes/011-cilium-choose-routing-mode.md)           |
| 012 | [Configure MTU Properly](kubernetes/012-cilium-configure-mtu-properly.md)               |
| 013 | [Enable Hubble for Observability](kubernetes/013-cilium-enable-hubble-observability.md) |
| 014 | [Use Kube-Proxy Replacement](kubernetes/014-cilium-kubeproxy-replacement.md)            |
| 015 | [Configure Masquerading Correctly](kubernetes/015-cilium-configure-masquerading.md)     |
| 016 | [Use CiliumNetworkPolicies](kubernetes/016-cilium-network-policies.md)                  |
| 017 | [Configure eBPF for Performance](kubernetes/017-cilium-ebpf-configuration.md)           |
| 018 | [Enable Bandwidth Manager](kubernetes/018-cilium-bandwidth-manager.md)                  |

</details>

<details>
<summary><strong>Node.js</strong> -- 15 principles</summary>

| #   | Principle                                                                                  |
| --- | ------------------------------------------------------------------------------------------ |
| 001 | [Use Async/Await Over Callbacks](nodejs/001-use-async-await-over-callbacks.md)             |
| 002 | [Use Environment Variables for Config](nodejs/002-use-environment-variables-for-config.md) |
| 003 | [Use Proper Error Handling](nodejs/003-use-proper-error-handling.md)                       |
| 004 | [Use package.json Scripts](nodejs/004-use-package-json-scripts.md)                         |
| 005 | [Use ESLint and Prettier](nodejs/005-use-eslint-and-prettier.md)                           |
| 006 | [Use ESM Modules Consistently](nodejs/006-use-esm-modules-consistently.md)                 |
| 007 | [Lock Dependencies](nodejs/007-lock-dependencies.md)                                       |
| 008 | [Use Structured Logging](nodejs/008-use-structured-logging.md)                             |
| 009 | [Validate Inputs](nodejs/009-validate-inputs.md)                                           |
| 010 | [Use Dependency Injection](nodejs/010-use-dependency-injection.md)                         |
| 011 | [Handle Promises Properly](nodejs/011-handle-promises-properly.md)                         |
| 012 | [Use TypeScript for Type Safety](nodejs/012-use-typescript-for-type-safety.md)             |
| 013 | [Use Security Best Practices](nodejs/013-use-security-best-practices.md)                   |
| 014 | [Organize Project Structure](nodejs/014-organize-project-structure.md)                     |
| 015 | [Use Graceful Shutdown](nodejs/015-use-graceful-shutdown.md)                               |

</details>

<details>
<summary><strong>Python</strong> -- 25 principles</summary>

**General Best Practices**

| #   | Principle                                                                          |
| --- | ---------------------------------------------------------------------------------- |
| 001 | [Use Type Hints](python/001-use-type-hints.md)                                     |
| 002 | [Use Context Managers](python/002-use-context-managers.md)                         |
| 003 | [Follow PEP 8 Style Guide](python/003-follow-pep8-style-guide.md)                  |
| 004 | [Use Virtual Environments](python/004-use-virtual-environments.md)                 |
| 005 | [Write Comprehensive Docstrings](python/005-write-comprehensive-docstrings.md)     |
| 006 | [Handle Exceptions Properly](python/006-handle-exceptions-properly.md)             |
| 007 | [Use pathlib Over os.path](python/007-use-pathlib-over-os-path.md)                 |
| 008 | [Use Structured Logging](python/008-use-structured-logging.md)                     |
| 009 | [Avoid Mutable Default Arguments](python/009-avoid-mutable-default-arguments.md)   |
| 010 | [Use Comprehensions Appropriately](python/010-use-comprehensions-appropriately.md) |
| 011 | [Use Dataclasses](python/011-use-dataclasses.md)                                   |
| 012 | [Use f-strings for Formatting](python/012-use-f-strings-for-formatting.md)         |
| 013 | [Write Unit Tests with pytest](python/013-write-unit-tests-with-pytest.md)         |
| 014 | [Use Async/Await for I/O Operations](python/014-use-async-await-for-io.md)         |
| 015 | [Manage Dependencies Properly](python/015-manage-dependencies-properly.md)         |
| 016 | [Use Static Type Checking](python/016-use-static-type-checking.md)                 |
| 017 | [Follow Security Best Practices](python/017-follow-security-best-practices.md)     |

**AI Development**

| #   | Principle                                                                                |
| --- | ---------------------------------------------------------------------------------------- |
| 018 | [Manage API Keys Securely](python/018-manage-api-keys-securely.md)                       |
| 019 | [Handle API Rate Limits](python/019-handle-api-rate-limits.md)                           |
| 020 | [Use Streaming for Large Outputs](python/020-use-streaming-for-large-outputs.md)         |
| 021 | [Implement Proper Prompt Engineering](python/021-implement-proper-prompt-engineering.md) |
| 022 | [Use Vector Databases](python/022-use-vector-databases.md)                               |
| 023 | [Implement Response Caching](python/023-implement-response-caching.md)                   |
| 024 | [Use Structured Outputs](python/024-use-structured-outputs.md)                           |
| 025 | [Monitor Token Usage and Costs](python/025-monitor-token-usage-and-costs.md)             |

</details>

<details>
<summary><strong>AI</strong> -- 28 principles</summary>

**Prompt Engineering & LLM Integration**

| #   | Principle                                                                            |
| --- | ------------------------------------------------------------------------------------ |
| 001 | [Version Your Prompts](ai/001-version-your-prompts.md)                               |
| 002 | [Use System Prompts Effectively](ai/002-use-system-prompts-effectively.md)           |
| 003 | [Validate LLM Outputs](ai/003-validate-llm-outputs.md)                               |
| 008 | [Manage Context Windows](ai/008-manage-context-windows.md)                           |
| 011 | [Optimize Token Usage](ai/011-optimize-token-usage.md)                               |
| 013 | [Use Streaming for Responsiveness](ai/013-use-streaming-for-responsiveness.md)       |
| 016 | [Select Models Deliberately](ai/016-select-models-deliberately.md)                   |
| 026 | [Use Few-Shot Examples Strategically](ai/026-use-few-shot-examples-strategically.md) |

**RAG & Retrieval**

| #   | Principle                                                                        |
| --- | -------------------------------------------------------------------------------- |
| 004 | [Design RAG Pipelines Deliberately](ai/004-design-rag-pipelines-deliberately.md) |
| 005 | [Chunk Documents Strategically](ai/005-chunk-documents-strategically.md)         |
| 017 | [Use Embeddings Effectively](ai/017-use-embeddings-effectively.md)               |
| 018 | [Implement Hybrid Search](ai/018-implement-hybrid-search.md)                     |

**Safety, Security & Reliability**

| #   | Principle                                                                        |
| --- | -------------------------------------------------------------------------------- |
| 007 | [Handle LLM Failures Gracefully](ai/007-handle-llm-failures-gracefully.md)       |
| 009 | [Implement AI Guardrails](ai/009-implement-ai-guardrails.md)                     |
| 014 | [Implement Function Calling Safely](ai/014-implement-function-calling-safely.md) |
| 020 | [Detect and Mitigate Bias](ai/020-detect-and-mitigate-bias.md)                   |
| 021 | [Implement Human-in-the-Loop](ai/021-implement-human-in-the-loop.md)             |
| 022 | [Secure AI API Integrations](ai/022-secure-ai-api-integrations.md)               |
| 027 | [Prevent Prompt Injection](ai/027-prevent-prompt-injection.md)                   |
| 028 | [Handle Multimodal Inputs Safely](ai/028-handle-multimodal-inputs-safely.md)     |

**Operations, Testing & Evaluation**

| #   | Principle                                                                            |
| --- | ------------------------------------------------------------------------------------ |
| 006 | [Implement LLM Observability](ai/006-implement-llm-observability.md)                 |
| 010 | [Evaluate LLM Outputs Systematically](ai/010-evaluate-llm-outputs-systematically.md) |
| 012 | [Cache LLM Responses](ai/012-cache-llm-responses.md)                                 |
| 019 | [Version and Manage Models](ai/019-version-and-manage-models.md)                     |
| 023 | [Test AI Features Effectively](ai/023-test-ai-features-effectively.md)               |
| 024 | [Manage Training Data Quality](ai/024-manage-training-data-quality.md)               |

**Agent Architecture**

| #   | Principle                                                                              |
| --- | -------------------------------------------------------------------------------------- |
| 015 | [Build Agent Loops with Boundaries](ai/015-build-agent-loops-with-boundaries.md)       |
| 025 | [Design Multi-Agent Systems Carefully](ai/025-design-multi-agent-systems-carefully.md) |

</details>

<details>
<summary><strong>Go</strong> -- 20 principles</summary>

| #   | Principle                                                                    |
| --- | ---------------------------------------------------------------------------- |
| 001 | [Use Go Modules for Dependencies](go/001-use-go-modules.md)                  |
| 002 | [Handle Errors Explicitly](go/002-handle-errors-explicitly.md)               |
| 003 | [Use Interfaces for Abstraction](go/003-use-interfaces-for-abstraction.md)   |
| 004 | [Follow Effective Go Guidelines](go/004-follow-effective-go.md)              |
| 005 | [Use gofmt and Linters](go/005-use-gofmt-and-linters.md)                     |
| 006 | [Write Table-Driven Tests](go/006-write-table-driven-tests.md)               |
| 007 | [Use Context for Cancellation](go/007-use-context-for-cancellation.md)       |
| 008 | [Use Channels for Communication](go/008-use-channels-for-communication.md)   |
| 009 | [Avoid Goroutine Leaks](go/009-avoid-goroutine-leaks.md)                     |
| 010 | [Use Defer for Cleanup](go/010-use-defer-for-cleanup.md)                     |
| 011 | [Use Struct Embedding Over Inheritance](go/011-use-struct-embedding.md)      |
| 012 | [Keep Interfaces Small](go/012-keep-interfaces-small.md)                     |
| 013 | [Use Standard Library Packages](go/013-use-standard-library.md)              |
| 014 | [Avoid Package-Level State](go/014-avoid-package-level-state.md)             |
| 015 | [Use Meaningful Variable Names](go/015-use-meaningful-names.md)              |
| 016 | [Handle Panics Appropriately](go/016-handle-panics-appropriately.md)         |
| 017 | [Use Buffered Channels Carefully](go/017-use-buffered-channels-carefully.md) |
| 018 | [Follow Standard Project Layout](go/018-follow-project-layout.md)            |
| 019 | [Use Build Tags for Conditional Compilation](go/019-use-build-tags.md)       |
| 020 | [Write Benchmarks for Performance](go/020-write-benchmarks.md)               |

</details>

<details>
<summary><strong>Rust</strong> -- 20 principles</summary>

| #   | Principle                                                                        |
| --- | -------------------------------------------------------------------------------- |
| 001 | [Embrace Ownership and Borrowing](rust/001-embrace-ownership-and-borrowing.md)   |
| 002 | [Use Result and Option for Error Handling](rust/002-use-result-and-option.md)    |
| 003 | [Leverage the Type System](rust/003-leverage-the-type-system.md)                 |
| 004 | [Use Cargo Effectively](rust/004-use-cargo-effectively.md)                       |
| 005 | [Follow Rust API Guidelines](rust/005-follow-api-guidelines.md)                  |
| 006 | [Use rustfmt and clippy](rust/006-use-rustfmt-and-clippy.md)                     |
| 007 | [Write Comprehensive Tests](rust/007-write-comprehensive-tests.md)               |
| 008 | [Use Traits for Shared Behavior](rust/008-use-traits-for-shared-behavior.md)     |
| 009 | [Prefer Iterators Over Loops](rust/009-prefer-iterators-over-loops.md)           |
| 010 | [Use Pattern Matching](rust/010-use-pattern-matching.md)                         |
| 011 | [Avoid unwrap in Production](rust/011-avoid-unwrap-in-production.md)             |
| 012 | [Use Smart Pointers Appropriately](rust/012-use-smart-pointers-appropriately.md) |
| 013 | [Use async/await for Concurrency](rust/013-use-async-await-for-concurrency.md)   |
| 014 | [Implement Error Types Properly](rust/014-implement-error-types-properly.md)     |
| 015 | [Use Macros Sparingly](rust/015-use-macros-sparingly.md)                         |
| 016 | [Follow Module Organization](rust/016-follow-module-organization.md)             |
| 017 | [Use Lifetimes When Necessary](rust/017-use-lifetimes-when-necessary.md)         |
| 018 | [Prefer &str Over String for Parameters](rust/018-prefer-str-over-string.md)     |
| 019 | [Use Arc and Mutex for Shared State](rust/019-use-arc-mutex-for-shared-state.md) |
| 020 | [Leverage Zero-Cost Abstractions](rust/020-leverage-zero-cost-abstractions.md)   |

</details>

## Building Skills

If you modify the principle source files (the per-category Markdown files in directories like `security/`, `python/`, `go/`, etc.), you need to regenerate the skill files before committing.

Run the build script:

```bash
./build-skills.sh
```

This script:

1. Scans each category directory for principle Markdown files
2. Concatenates them into a single skill file per category
3. Adds YAML frontmatter with the skill name and trigger description
4. Appends linting/formatting guidance specific to each technology
5. Writes the output to `skills/<category>-principles.md`

Always run `build-skills.sh` after editing principles and commit the updated skill files alongside your source changes.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding principles, supporting new technologies, and submitting PRs.

## License

This project is licensed under the [MIT License](LICENSE).
