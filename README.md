# central-ci

A library of reusable GitHub Actions composite actions and workflows.

## Actions

### `setup-git-config`

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

| Name | Description | Required | Default |
|---|---|---|---|
| `git-user-name` | Value for `git config user.name` | No | `github-actions[bot]` |
| `git-user-email` | Value for `git config user.email` | No | `github-actions[bot]@users.noreply.github.com` |

### `git-tag`

Creates and pushes a Git tag to origin. Requires the calling job to have `contents: write` permission.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/git-tag@v1
  with:
    new-tag: "v1.2.3"
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `new-tag` | Tag name to create and push (e.g. `v1.2.3`) | Yes | — |
| `token` | GitHub token with `contents:write` permission | Yes | — |

### `next-version`

Computes the next semver tag from [Conventional Commits](https://www.conventionalcommits.org/). Supports an optional service prefix or plain `vX.Y.Z` tags.

| Commit pattern | Bump |
| --- | --- |
| `feat!:`, `fix!:`, `BREAKING CHANGE` | major |
| `feat:` | minor |
| anything else | patch |

**Usage (plain tags):**

```yaml
- uses: mmastersvz/central-ci/actions/next-version@v1
  id: version
# outputs: v1.2.3
```

**Usage (service prefix):**

```yaml
- uses: mmastersvz/central-ci/actions/next-version@v1
  id: version
  with:
    service: "my-service"
# outputs: my-service/v1.2.3
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `service` | Service name used as tag prefix. Omit for plain `vX.Y.Z`. | No | `""` |
| `token` | GitHub token for `git fetch` on private repos. | No | `github.token` |

**Outputs:**

| Name | Description |
| --- | --- |
| `new-tag` | The next computed tag (e.g. `v1.2.3` or `my-service/v1.2.3`) |
| `previous-tag` | The most recent matching tag, or empty string if none exists |
| `release-type` | The bump type applied: `major`, `minor`, or `patch` |
| `marketing-version` | The bare version number without prefix or `v` (e.g. `1.2.3`) |

## Testing

Test workflows live in `.github/workflows/` and are prefixed with `test-`.

To run them:

1. Go to **Actions** → select the test workflow (e.g. `Test: setup-git-config`)
2. Click **Run workflow** → choose a branch → **Run workflow**

Or via CLI:

```sh
gh workflow run test-setup-git-config.yml
```
