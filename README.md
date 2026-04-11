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

## Testing

Trigger the test suite via `workflow_dispatch` on any workflow under `tests/`.
