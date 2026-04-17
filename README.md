# central-ci

A library of reusable GitHub Actions composite actions and reusable workflows — batteries-included CI for Go, Node, Python, Java, and .NET services.

## Table of Contents

- [Repository Standards](#repository-standards)
- [Versioning](#versioning)
- [Reusable Workflows](#reusable-workflows)
  - [lib-ci-go](#lib-ci-go)
  - [lib-ci-node](#lib-ci-node)
  - [lib-ci-python](#lib-ci-python)
  - [lib-ci-java](#lib-ci-java)
  - [lib-ci-dotnet](#lib-ci-dotnet)
- [Actions](#actions)
  - [Security](#security-actions)
  - [Build & Test](#build--test-actions)
  - [Docker](#docker-actions)
  - [Setup & Infrastructure](#setup--infrastructure-actions)
  - [Release & Versioning](#release--versioning-actions)
- [Contributing](#contributing)
- [Testing](#testing)

---

## Repository Standards

### Workflow Naming

All files in `.github/workflows/` are prefixed based on their scope:

| Prefix   | Category        | Intent                                                                                                |
| :------- | :-------------- | :---------------------------------------------------------------------------------------------------- |
| `lib-`   | **Library**     | **Public API.** Reusable workflows intended to be called by external repositories.                    |
| `test-`  | **Validation**  | **Internal Tests.** Workflows that exercise composite actions to ensure stability before release.     |
| `local-` | **Maintenance** | **Internal Ops.** CI/CD for _this_ repository (linting, tagging, releasing `central-ci`).            |

### Directory Structure

```text
.github/
└── workflows/
    ├── lib-[name].yml        # Reusable workflows (public API)
    ├── test-[name].yml       # Test workflows for composite actions
    └── local-[name].yml      # Internal maintenance
actions/
└── [action-name]/
    └── action.yml            # Composite actions
scripts/                      # Bash/Python scripts used by actions
tests/
└── fixtures/                 # Test fixture apps (e.g. go-app)
```

---

## Versioning

This repo uses a single version for all actions and workflows. Pin to a major version tag (`@v1`) to receive non-breaking updates automatically.

```yaml
# Recommended — receives patch and minor updates automatically
uses: mmastersvz/central-ci/actions/resolve-version@v1

# Pinned — use when you need a specific fix or need to audit changes
uses: mmastersvz/central-ci/actions/resolve-version@v1.2.3
```

---

## Reusable Workflows

All `lib-ci-*` workflows share the same job pipeline:

| Job       | Description                                                           |
| --------- | --------------------------------------------------------------------- |
| `secrets` | Gitleaks + TruffleHog secret scanning                                 |
| `sast-pre`| Semgrep static analysis                                               |
| `sca`     | Trivy filesystem SCA scan                                             |
| `setup`   | Version resolution, Docker metadata, lint                             |
| `build`   | Build, test, language-specific audit, CodeQL, Docker publish, ZAP DAST, Trivy image scan |
| `gate`    | Asserts all prior jobs passed; writes a status table to job summary   |
| `release` | Creates git tag + GitHub release (non-PR only, requires gate to pass) |

All workflows enforce `concurrency` per service — parallel PR runs are isolated; main-branch runs queue.

---

### `lib-ci-go`

Full CI pipeline for Go services.

**Usage:**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-go.yml@v1
    with:
      app-name: my-go-service
      app-dir: services/my-go-service
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                 | Description                                    | Required | Default              |
| -------------------- | ---------------------------------------------- | -------- | -------------------- |
| `app-name`           | Service name (used for tags and image names)   | Yes      | —                    |
| `app-dir`            | Path to service root (where `go.mod` lives)    | No       | `.`                  |
| `tool-versions-path` | Path to `.tool-versions` file                  | No       | `./.tool-versions`   |
| `dast-on-pr`         | Run ZAP DAST scan on pull requests             | No       | `true`               |
| `dast-on-push`       | Run ZAP DAST scan on push to main              | No       | `true`               |

**Secrets:** `github-token` (required)

**Outputs:** `build-version`

**Setup job lints with:** `golangci-lint`  
**Build job security checks:** `govulncheck`, CodeQL (`go`, `autobuild`), ZAP DAST, Trivy image scan

---

### `lib-ci-node`

Full CI pipeline for Node.js services.

**Usage:**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-node.yml@v1
    with:
      app-name: my-node-service
      app-dir: services/my-node-service
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                 | Description                                    | Required | Default              |
| -------------------- | ---------------------------------------------- | -------- | -------------------- |
| `app-name`           | Service name                                   | Yes      | —                    |
| `app-dir`            | Path to service root                           | Yes      | —                    |
| `tool-versions-path` | Path to `.tool-versions` file                  | No       | `./.tool-versions`   |
| `dast-on-pr`         | Run ZAP DAST scan on pull requests             | No       | `true`               |
| `dast-on-push`       | Run ZAP DAST scan on push to main              | No       | `true`               |

**Secrets:** `github-token` (required)

**Outputs:** `build-version`

**Setup job lints with:** `npm run lint`  
**Build job security checks:** `npm audit --audit-level=high`, CodeQL (`javascript`, `none`), ZAP DAST, Trivy image scan

---

### `lib-ci-python`

Full CI pipeline for Python services.

**Usage:**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-python.yml@v1
    with:
      app-name: my-python-service
      app-dir: services/my-python-service
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Usage (suppressing an unfixable CVE):**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-python.yml@v1
    with:
      app-name: my-python-service
      app-dir: services/my-python-service
      # suppress until upstream fix is available
      pip-audit-args: "--ignore-vuln GHSA-xxxx-yyyy-zzzz"
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                 | Description                                                       | Required | Default              |
| -------------------- | ----------------------------------------------------------------- | -------- | -------------------- |
| `app-name`           | Service name                                                      | Yes      | —                    |
| `app-dir`            | Path to service root                                              | No       | `.`                  |
| `tool-versions-path` | Path to `.tool-versions` file                                     | No       | `./.tool-versions`   |
| `dast-on-pr`         | Run ZAP DAST scan on pull requests                                | No       | `true`               |
| `dast-on-push`       | Run ZAP DAST scan on push to main                                 | No       | `true`               |
| `pip-audit-args`     | Extra arguments forwarded to `pip-audit` (e.g. `--ignore-vuln`) | No       | `""`                 |

**Secrets:** `github-token` (required)

**Outputs:** `build-version`

**Setup job lints with:** `ruff`  
**Build job security checks:** `pip-audit`, CodeQL (`python`, `none`), ZAP DAST, Trivy image scan

---

### `lib-ci-java`

Full CI pipeline for Java/Maven services.

**Usage:**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-java.yml@v1
    with:
      app-name: my-java-service
      app-dir: services/my-java-service
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                          | Description                                                                        | Required | Default              |
| ----------------------------- | ---------------------------------------------------------------------------------- | -------- | -------------------- |
| `app-name`                    | Service name                                                                       | Yes      | —                    |
| `app-dir`                     | Path to service root                                                               | No       | `.`                  |
| `tool-versions-path`          | Path to `.tool-versions` file                                                      | No       | `./.tool-versions`   |
| `dast-on-pr`                  | Run ZAP DAST scan on pull requests                                                 | No       | `true`               |
| `dast-on-push`                | Run ZAP DAST scan on push to main                                                  | No       | `true`               |
| `skip-maven-dependency-audit` | Skip the OWASP Dependency Check Maven plugin (slow; disabled by default)           | No       | `true`               |

**Secrets:** `github-token` (required), `nvd-api-key` (optional — speeds up OWASP Dependency Check)

**Outputs:** `build-version`

**Setup job lints with:** `mvn checkstyle:check`, `mvn pmd:check`  
**Build job security checks:** OWASP Dependency Check (opt-in), CodeQL (`java`, `manual`), ZAP DAST, Trivy image scan

> **`.tool-versions` format for Java:** `java temurin-21.0.7+6.0.LTS` — distribution and version are parsed automatically.

---

### `lib-ci-dotnet`

Full CI pipeline for .NET services.

**Usage:**

```yaml
jobs:
  ci:
    uses: mmastersvz/central-ci/.github/workflows/lib-ci-dotnet.yml@v1
    with:
      app-name: my-dotnet-service
      app-dir: services/my-dotnet-service
      project-path: src/MyService
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                 | Description                                      | Required | Default              |
| -------------------- | ------------------------------------------------ | -------- | -------------------- |
| `app-name`           | Service name                                     | Yes      | —                    |
| `app-dir`            | Path to service root                             | No       | `.`                  |
| `project-path`       | Path to the project folder (relative to app-dir) | Yes      | —                    |
| `tool-versions-path` | Path to `.tool-versions` file                    | No       | `./.tool-versions`   |
| `dast-on-pr`         | Run ZAP DAST scan on pull requests               | No       | `true`               |
| `dast-on-push`       | Run ZAP DAST scan on push to main                | No       | `true`               |

**Secrets:** `github-token` (required)

**Setup job lints with:** `dotnet format --verify-no-changes`  
**Build job security checks:** `dotnet list package --vulnerable`, CodeQL (`csharp`, `none`), ZAP DAST, Trivy image scan

---

## Actions

### Security Actions

---

#### `security-secrets-scans`

Scans git history for leaked secrets using Gitleaks and TruffleHog.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/security-secrets-scans@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                    | Description                                      | Required | Default           |
| ----------------------- | ------------------------------------------------ | -------- | ----------------- |
| `github-token`          | GitHub token for Gitleaks authentication         | Yes      | —                 |
| `default-branch`        | Branch used as TruffleHog scan base              | No       | `main`            |
| `trufflehog-extra-args` | Extra arguments passed to TruffleHog             | No       | `--only-verified` |
| `do-checkout`           | Perform a git checkout before scanning           | No       | `true`            |

---

#### `security-sast-pre-scans`

Runs Semgrep static analysis (pre-build). Supports both OSS mode and the Semgrep AppSec Platform.

**Usage (OSS mode):**

```yaml
- uses: mmastersvz/central-ci/actions/security-sast-pre-scans@v1
  with:
    working-directory: services/my-service
```

**Inputs:**

| Name                   | Description                                                                    | Required | Default                                    |
| ---------------------- | ------------------------------------------------------------------------------ | -------- | ------------------------------------------ |
| `skip-semgrep`         | Skip the scan entirely                                                         | No       | `false`                                    |
| `semgrep-app-token`    | Semgrep AppSec Platform token. If omitted, runs in OSS mode.                  | No       | —                                          |
| `semgrep-config`       | Space-separated rulesets for OSS mode (ignored when token is provided)         | No       | `p/default p/owasp-top-ten p/cwe-top-25 p/secrets` |
| `semgrep-output-file`  | Filename for the SARIF output                                                  | No       | `semgrep-results.sarif`                    |
| `semgrep-image-tag`    | Semgrep Docker image tag                                                       | No       | `1.159.0`                                  |
| `do-checkout`          | Perform a git checkout before scanning                                         | No       | `true`                                     |
| `working-directory`    | Directory to scan                                                              | No       | `.`                                        |

---

#### `security-sast-post-scans`

Runs CodeQL static analysis (post-build). Use `build-mode: none` for interpreted languages and `autobuild` or `manual` for compiled languages.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/security-sast-post-scans@v1
  with:
    codeql-languages: javascript
    codeql-build-mode: none
    codeql-category-suffix: my-service
    do-checkout: "false"  # already checked out in prior step
```

**Inputs:**

| Name                     | Description                                                                          | Required | Default  |
| ------------------------ | ------------------------------------------------------------------------------------ | -------- | -------- |
| `codeql-languages`       | Comma-separated CodeQL languages (e.g. `javascript,python`)                         | Yes      | —        |
| `codeql-build-mode`      | `none` for interpreted langs; `autobuild` or `manual` for compiled                  | No       | `none`   |
| `codeql-config-file`     | Path to a custom CodeQL config (useful for `paths`/`paths-ignore` in monorepos)     | No       | `""`     |
| `codeql-category-suffix` | Suffix appended to the CodeQL category (e.g. `my-service` → `codeql-my-service`)   | No       | `""`     |
| `codeql-upload-results`  | Upload SARIF to GitHub Code Scanning                                                 | No       | `false`  |
| `skip-codeql`            | Skip the scan entirely                                                               | No       | `false`  |
| `do-checkout`            | Perform a git checkout before scanning                                               | No       | `true`   |
| `working-directory`      | Working directory for the scan                                                       | No       | `.`      |

---

#### `security-sca-scans`

Runs a Trivy filesystem SCA (Software Composition Analysis) scan and uploads results as SARIF.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/security-sca-scans@v1
  with:
    app-name: my-service
    scan-ref: services/my-service
```

**Inputs:**

| Name       | Description                                    | Required | Default          |
| ---------- | ---------------------------------------------- | -------- | ---------------- |
| `app-name` | Application name (used in the output filename) | Yes      | —                |
| `scan-ref` | Path to scan                                   | No       | `.`              |
| `severity` | Severity levels to include                     | No       | `CRITICAL,HIGH`  |
| `format`   | Output format                                  | No       | `sarif`          |

---

#### `security-dast-zap`

Starts the built Docker image, runs an OWASP ZAP baseline (passive) scan against it, then tears the container down.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/security-dast-zap@v1
  with:
    image-ref: ${{ needs.setup.outputs.docker-tags }}
    load-local: ${{ needs.setup.outputs.docker-push != 'true' }}
    build-context: ./services/my-service
    cache-scope: my-service
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name                    | Description                                                                          | Required | Default  |
| ----------------------- | ------------------------------------------------------------------------------------ | -------- | -------- |
| `image-ref`             | Full image reference to scan                                                         | Yes      | —        |
| `github-token`          | GitHub token for ZAP to post a PR comment                                            | Yes      | —        |
| `port`                  | Port the container listens on                                                        | No       | `8080`   |
| `target`                | URL ZAP will scan. Defaults to `http://localhost:<port>`.                            | No       | `""`     |
| `load-local`            | Build and load the image locally before scanning (use when `docker-push` is false)  | No       | `false`  |
| `build-context`         | Docker build context path (used when `load-local: true`)                             | No       | `.`      |
| `cache-scope`           | GHA cache scope (used when `load-local: true`)                                       | No       | `""`     |
| `rules-file`            | Path to a ZAP rules `.tsv` file for suppressing false positives                     | No       | `""`     |
| `cmd-options`           | Additional ZAP command-line options                                                  | No       | `-I`     |
| `fail-on-warn`          | Fail if ZAP reports any WARN-level alerts                                            | No       | `false`  |
| `startup-wait-seconds`  | Seconds to wait for the container to become ready                                    | No       | `15`     |

---

#### `trivy-image-scan`

Scans a container image for vulnerabilities using Trivy and uploads results as SARIF.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/trivy-image-scan@v1
  with:
    app-name: my-service
    image-ref: ${{ needs.setup.outputs.docker-tags }}
```

**Inputs:**

| Name        | Description                                    | Required | Default         |
| ----------- | ---------------------------------------------- | -------- | --------------- |
| `app-name`  | Application name (used in the output filename) | Yes      | —               |
| `image-ref` | Container image reference to scan              | Yes      | —               |
| `severity`  | Severity levels to include                     | No       | `CRITICAL,HIGH` |

---

### Build & Test Actions

---

#### `go-build-test`

Sets up Go, runs `go vet`, tests with coverage, and builds a statically linked binary (`CGO_ENABLED=0 GOOS=linux`).

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/go-build-test@v1
  with:
    app-dir: services/my-go-service
```

**Inputs:**

| Name      | Description                             | Required | Default |
| --------- | --------------------------------------- | -------- | ------- |
| `app-dir` | Directory where `go.mod` is located     | Yes      | `.`     |

**Artifacts produced:** `go-coverage` (coverage.out, retained 7 days)

---

#### `dotnet-build-test`

Restores, builds (`dotnet publish`), and tests a .NET project.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/dotnet-build-test@v1
  with:
    build-version: ${{ needs.setup.outputs.build-version }}
    dotnet-version: "8.0.x"
    project-path: src/MyService
    working-directory: services/my-dotnet-service
```

**Inputs:**

| Name                | Description                              | Required | Default            |
| ------------------- | ---------------------------------------- | -------- | ------------------ |
| `build-version`     | Version string to stamp into the build   | Yes      | —                  |
| `dotnet-version`    | .NET SDK version                         | No       | `8.0.x`            |
| `project-path`      | Path to the project folder               | No       | `src/DotnetService`|
| `working-directory` | Working directory for the action         | No       | `./`               |

---

#### `lint`

Language-aware linting. Dispatches to the appropriate linter based on `language`.

| Language   | Linter                |
| ---------- | --------------------- |
| `go`       | `golangci-lint`       |
| `node`     | `npm ci && npm run lint` |
| `python`   | `ruff check .`        |

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/lint@v1
  with:
    language: go
```

**Inputs:**

| Name       | Description                                      | Required | Default |
| ---------- | ------------------------------------------------ | -------- | ------- |
| `language` | Language to lint: `go`, `node`, or `python`      | Yes      | —       |

---

### Docker Actions

---

#### `docker-publish`

Logs in to GHCR, builds a multi-platform image (`linux/amd64,linux/arm64`), and optionally pushes it. Includes SBOM and provenance attestation.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/docker-publish@v1
  with:
    registry-password: ${{ secrets.GITHUB_TOKEN }}
    docker-push: ${{ needs.setup.outputs.docker-push }}
    docker-tags: ${{ needs.setup.outputs.docker-tags }}
    context: ./services/my-service
    cache-scope: my-service
```

**Inputs:**

| Name                | Description                                           | Required | Default |
| ------------------- | ----------------------------------------------------- | -------- | ------- |
| `registry-password` | GitHub token or registry password                     | Yes      | —       |
| `docker-push`       | Whether to push the image (`"true"` or `"false"`)     | Yes      | `false` |
| `docker-tags`       | Comma-separated list of image tags                    | Yes      | —       |
| `context`           | Docker build context                                  | No       | `.`     |
| `cache-scope`       | GHA cache scope for layer caching                     | Yes      | —       |

---

#### `setup-docker`

Determines whether to push the image and generates formatted GHCR image tags. Used in the `setup` job of all `lib-ci-*` workflows.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-docker@v1
  id: docker
  with:
    app-name: my-service
    app-version: ${{ steps.version.outputs.build-version }}
```

**Inputs:**

| Name          | Description                     | Required | Default |
| ------------- | ------------------------------- | -------- | ------- |
| `app-name`    | Application name                | Yes      | —       |
| `app-version` | Resolved semantic version       | Yes      | —       |

**Outputs:**

| Name          | PR value                              | Push value                                     |
| ------------- | ------------------------------------- | ---------------------------------------------- |
| `docker-push` | `false`                               | `true`                                         |
| `docker-tags` | `ghcr.io/org/repo/app:sha,…:pr-N`    | `ghcr.io/org/repo/app:sha,…:1.2.3,…:latest`  |

---

### Setup & Infrastructure Actions

---

#### `setup`

Captures the commit SHA and resolves the service version (wraps `resolve-version`). Used as the first step in all `lib-ci-*` setup jobs.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup@v1
  id: prep
  with:
    service-name: my-service
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name           | Description                           | Required | Default      |
| -------------- | ------------------------------------- | -------- | ------------ |
| `service-name` | Service name for tag prefixing        | No       | `go-service` |
| `github-token` | GitHub token for version resolution   | Yes      | —            |

**Outputs:** `commit_sha`, `new-tag`, `build-version`, `previous-tag`, `release-type`, `is-prerelease`

---

#### `setup-tools`

Parses a `.tool-versions` file and outputs versions as a JSON object.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-tools@v1
  id: tools
  with:
    tools: "java,maven"
    tool-versions-path: services/my-service/.tool-versions

- run: echo "Java version is ${{ fromJSON(steps.tools.outputs.tool-versions).java }}"
```

**Inputs:**

| Name                 | Description                                                        | Required | Default         |
| -------------------- | ------------------------------------------------------------------ | -------- | --------------- |
| `tools`              | Comma-separated list of tools to extract (e.g. `java,maven`)       | No       | `""`            |
| `language`           | Fallback single tool if `tools` is empty                           | No       | `java`          |
| `tool-versions-path` | Path to `.tool-versions` file                                      | No       | `.tool-versions`|

**Outputs:**

| Name            | Description                                              |
| --------------- | -------------------------------------------------------- |
| `tool-versions` | JSON object with all extracted tool versions             |

---

#### `setup-and-cache`

Language-aware runtime setup with built-in caching. A convenience wrapper over `actions/setup-go`, `actions/setup-node`, `actions/setup-python`, and `docker/setup-buildx-action`.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-and-cache@v1
  with:
    language: go
```

**Inputs:**

| Name        | Description                                                              | Required | Default                    |
| ----------- | ------------------------------------------------------------------------ | -------- | -------------------------- |
| `language`  | `go`, `node`, `python`, `docker`, or `multi`                             | Yes      | —                          |
| `platforms` | Target platforms for Docker builds (only used for `docker`/`multi`)      | No       | `linux/amd64,linux/arm64`  |

---

#### `setup-git-config`

Configures Git `user.name` and `user.email` globally on the runner.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-git-config@v1
```

**With custom values:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-git-config@v1
  with:
    git-user-name: "my-bot"
    git-user-email: "my-bot@example.com"
```

**Inputs:**

| Name             | Description                       | Required | Default                                        |
| ---------------- | --------------------------------- | -------- | ---------------------------------------------- |
| `git-user-name`  | Value for `git config user.name`  | No       | `github-actions[bot]`                          |
| `git-user-email` | Value for `git config user.email` | No       | `github-actions[bot]@users.noreply.github.com` |

---

### Release & Versioning Actions

---

#### `release`

Creates a git tag and GitHub release. Composes `setup-git-config`, `git-tag`, and `gh-release` into a single step. Used by all `lib-ci-*` workflows.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/release@v1
  with:
    new-tag:       ${{ needs.setup.outputs.new-tag }}
    build-version: ${{ needs.setup.outputs.build-version }}
    previous-tag:  ${{ needs.setup.outputs.previous-tag }}
    release-type:  ${{ needs.setup.outputs.release-type }}
    token:         ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name            | Description                                    | Required | Default |
| --------------- | ---------------------------------------------- | -------- | ------- |
| `new-tag`       | Tag to create (e.g. `api/v1.2.3`)              | Yes      | —       |
| `build-version` | Bare version for the release title (e.g. `1.2.3`) | Yes   | —       |
| `previous-tag`  | Previous tag for release notes range           | No       | `""`    |
| `release-type`  | Bump type: `major`, `minor`, `patch`            | No       | `""`    |
| `token`         | GitHub token with `contents:write`             | Yes      | —       |

---

#### `git-tag`

Creates and pushes a git tag to origin. Requires `contents: write` permission.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/git-tag@v1
  with:
    new-tag: "v1.2.3"
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name      | Description                                   | Required | Default |
| --------- | --------------------------------------------- | -------- | ------- |
| `new-tag` | Tag name to create and push                   | Yes      | —       |
| `token`   | GitHub token with `contents:write` permission | Yes      | —       |

---

#### `gh-release`

Creates a GitHub release for an existing git tag.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/gh-release@v1
  with:
    tag: ${{ steps.version.outputs.new-tag }}
    title: ${{ steps.version.outputs.build-version }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name             | Description                                                               | Required | Default  |
| ---------------- | ------------------------------------------------------------------------- | -------- | -------- |
| `tag`            | Existing git tag to release                                               | Yes      | —        |
| `title`          | Release title. Falls back to `tag` if omitted.                            | No       | `""`     |
| `token`          | GitHub token with `contents:write` permission                             | Yes      | —        |
| `notes`          | Release notes markdown. When provided, `generate-notes` is ignored.       | No       | `""`     |
| `generate-notes` | Auto-generate release notes from merged PRs. Ignored when `notes` is set. | No       | `true`   |
| `release-type`   | Bump type for step summary display only                                   | No       | `""`     |
| `previous-tag`   | Previous tag for step summary display only                                | No       | `""`     |

---

#### `changelog`

Generates a Conventional Commits grouped changelog between two tags.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/changelog@v1
  id: changelog
  with:
    previous-tag: ${{ steps.version.outputs.previous-tag }}
    new-tag: ${{ steps.version.outputs.new-tag }}
```

**Inputs:**

| Name           | Description                                      | Required | Default |
| -------------- | ------------------------------------------------ | -------- | ------- |
| `previous-tag` | Tag to diff from. Includes all commits if empty. | No       | `""`    |
| `new-tag`      | Tag to diff to.                                  | No       | `HEAD`  |

**Outputs:**

| Name    | Description                |
| ------- | -------------------------- |
| `notes` | Grouped changelog markdown |

**Output format:**

```markdown
## Breaking Changes
- feat!: remove legacy auth endpoint (`a1b2c3d`)

## Features
- feat: add service prefix support to next-version (`e4f5g6h`)

## Bug Fixes
- fix: correct GITHUB_RUN_NUMBER usage in shell scripts (`i7j8k9l`)

## Other Changes
- chore: update actionlint config (`m1n2o3p`)

**Full Changelog**: https://github.com/org/repo/compare/v1.0.0...v1.1.0
```

---

#### `resolve-version`

Auto-selects `next-version` for release builds or `pr-version` for pull request builds. This is the recommended entry point for workflows that need version info.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/resolve-version@v1
  id: version

- run: echo "Tag is ${{ steps.version.outputs.new-tag }}"
```

**Inputs:**

| Name        | Description                                                   | Required | Default        |
| ----------- | ------------------------------------------------------------- | -------- | -------------- |
| `service`   | Service name for tag prefixing, passed to `next-version`.     | No       | `""`           |
| `token`     | GitHub token for `git fetch`, passed to `next-version`.       | No       | `github.token` |
| `pr-number` | Forces PR versioning when provided, regardless of event type. | No       | `""`           |

**Outputs:**

| Name            | Release example | PR example           |
| --------------- | --------------- | -------------------- |
| `new-tag`       | `v1.2.3`        | `0.0.0-pr.123.5.1`   |
| `build-version` | `1.2.3`         | `0.0.0-pr.123.5.1`   |
| `previous-tag`  | `v1.2.2`        | `""`                 |
| `release-type`  | `minor`         | `prerelease`         |
| `is-prerelease` | `false`         | `true`               |

---

#### `next-version`

Computes the next semver tag from [Conventional Commits](https://www.conventionalcommits.org/). Supports a service prefix or plain `vX.Y.Z` tags.

| Commit pattern                       | Bump  |
| ------------------------------------ | ----- |
| `feat!:`, `fix!:`, `BREAKING CHANGE` | major |
| `feat:`                              | minor |
| anything else                        | patch |

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/next-version@v1
  id: version
  with:
    service: "my-service"  # omit for plain vX.Y.Z tags
```

**Inputs:**

| Name      | Description                                                | Required | Default        |
| --------- | ---------------------------------------------------------- | -------- | -------------- |
| `service` | Service name used as tag prefix. Omit for plain `vX.Y.Z`. | No       | `""`           |
| `token`   | GitHub token for `git fetch` on private repos.             | No       | `github.token` |

**Outputs:**

| Name            | Description                                                   |
| --------------- | ------------------------------------------------------------- |
| `new-tag`       | Next computed tag (e.g. `v1.2.3` or `my-service/v1.2.3`)    |
| `previous-tag`  | Most recent matching tag, or empty if none exists             |
| `release-type`  | Bump type applied: `major`, `minor`, or `patch`               |
| `build-version` | Bare version without prefix or `v` (e.g. `1.2.3`)            |

---

#### `pr-version`

Computes a pre-release version string for pull request builds.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/pr-version@v1
  id: version
```

**Inputs:**

| Name        | Description                                               | Required | Default |
| ----------- | --------------------------------------------------------- | -------- | ------- |
| `pr-number` | PR number. Auto-detected from event context when omitted. | No       | `""`    |

**Outputs:**

| Name            | Description                                           |
| --------------- | ----------------------------------------------------- |
| `new-tag`       | Pre-release version string (e.g. `0.0.0-pr.123.5.1`) |
| `build-version` | Same as `new-tag` for PR builds                       |
| `previous-tag`  | Always empty for PR builds                            |
| `release-type`  | Always `prerelease`                                   |
| `build-id`      | Dot-separated build identifier (e.g. `123.5.1`)       |

---

#### `move-major-tag`

Moves the floating major version tag (e.g. `v1`) to point at a new semver tag. Requires `contents: write` permission.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/move-major-tag@v1
  with:
    tag: ${{ steps.version.outputs.new-tag }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name    | Description                                                                    | Required | Default |
| ------- | ------------------------------------------------------------------------------ | -------- | ------- |
| `tag`   | Full semver tag to derive the major version from (e.g. `v1.2.3` → moves `v1`) | Yes      | —       |
| `token` | GitHub token with `contents:write` permission                                  | Yes      | —       |

**Outputs:**

| Name        | Description                                       |
| ----------- | ------------------------------------------------- |
| `major-tag` | The major version tag that was moved (e.g. `v1`)  |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for architectural guidelines, including when to write a composite action vs. a reusable workflow.

---

## Testing

See [TESTING.md](TESTING.md) for local testing instructions (`act`, `actionlint`, direct script execution).

Test workflows live in `.github/workflows/test-*.yml`. The following actions have test coverage:

| Action / Script          | Test workflow                       |
| ------------------------ | ----------------------------------- |
| `changelog`              | `test-changelog.yml`                |
| `gh-release`             | `test-gh-release.yml`               |
| `git-tag`                | `test-git-tag.yml`                  |
| `go-build-test`          | `test-go-build-test.yml`            |
| `move-major-tag`         | `test-move-major-tag.yml`           |
| `next-version`           | `test-next-version.yml`             |
| `pr-version`             | `test-pr-version.yml`               |
| `resolve-version`        | `test-resolve-version.yml`          |
| `security-sast-post-scans` | `test-security-sast-post-scans.yml` |
| `security-sast-pre-scans`  | `test-security-sast-pre-scans.yml`  |
| `security-sca-scans`     | `test-security-sca-scans.yml`       |
| `setup-docker`           | `test-setup-docker.yml`             |
| `setup-git-config`       | `test-setup-git-config.yml`         |
| `setup-tools`            | `test-setup-tools.yml`              |

To run a test workflow:

```sh
gh workflow run test-setup-docker.yml
```

Or go to **Actions** → select the workflow → **Run workflow**.
