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

## Testing

Test workflows live in `.github/workflows/` and are prefixed with `test-`.

To run them:

1. Go to **Actions** → select the test workflow (e.g. `Test: setup-git-config`)
2. Click **Run workflow** → choose a branch → **Run workflow**

Or via CLI:

```sh
gh workflow run test-setup-git-config.yml
```
