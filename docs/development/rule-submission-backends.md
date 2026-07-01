# Rule Submission Backends

The Osprey UI's rule-drafting endpoints write SML through a pluggable
**submission backend**. The backend decides where a draft goes when an
operator clicks Submit: a GitHub PR, a filesystem path, an internal Gerrit,
or anything else. The editor, validator, and Rule Registry are the same in
every deployment; only the backend changes.

## Picking a backend

Set `OSPREY_RULES_SUBMISSION_BACKEND` on the `osprey-ui-api` process:

| Value | What it does | Required env vars |
|---|---|---|
| `null` (default) | Returns 503 on any submit/list call. Ships as the default so an unconfigured install never writes anything. | none |
| `github` | Opens a PR on a configured repo. Works with github.com and GitHub Enterprise. | `OSPREY_RULES_REPO`, `OSPREY_GITHUB_TOKEN` (+ optionals) |
| `gitlab` | Opens a merge request on a configured project. Works with gitlab.com and self-hosted GitLab. | `OSPREY_GITLAB_PROJECT`, `OSPREY_GITLAB_TOKEN` (+ optionals) |
| `local` | Writes SML directly to a mounted directory. For self-hosted setups whose deploy pipeline already syncs a rules directory into the engine. | `OSPREY_RULES_LOCAL_PATH` |

### `github`

| Var | Default | Notes |
|---|---|---|
| `OSPREY_RULES_REPO` | _required_ | `owner/name` of the repo to PR against. |
| `OSPREY_GITHUB_TOKEN` | _required_ | Fine-grained PAT scoped to `Contents: read/write` and `Pull requests: read/write` on the repo. |
| `OSPREY_GITHUB_API_URL` | `https://api.github.com` | Set for GitHub Enterprise: e.g. `https://github.acme.example/api/v3`. |
| `OSPREY_RULES_BASE_BRANCH` | `main` | The branch PRs target. |
| `OSPREY_RULES_PATH_IN_REPO` | _(none)_ | Subdirectory inside the repo where rule files live, e.g. `example_rules`. Leave empty if rules sit at the repo root. |

### `gitlab`

| Var | Default | Notes |
|---|---|---|
| `OSPREY_GITLAB_PROJECT` | _required_ | `namespace/project` of the project to MR against (e.g. `myorg/osprey-rules`). |
| `OSPREY_GITLAB_TOKEN` | _required_ | Project or personal access token with the `api` scope. |
| `OSPREY_GITLAB_URL` | `https://gitlab.com` | Set for self-hosted GitLab: e.g. `https://gitlab.mycompany.example`. |
| `OSPREY_RULES_BASE_BRANCH` | `main` | The branch merge requests target. Shared with the `github` backend. |
| `OSPREY_RULES_PATH_IN_REPO` | _(none)_ | Subdirectory inside the project where rule files live. Shared with the `github` backend. |

### `local`

| Var | Default | Notes |
|---|---|---|
| `OSPREY_RULES_LOCAL_PATH` | _required_ | Absolute path to the directory the backend writes SML into. Must already exist. Submissions take effect immediately; there's no review queue. |

## Adding a new backend

A backend is one class that satisfies the `RuleSubmissionBackend` Protocol in
`osprey_worker/src/osprey/worker/ui_api/osprey/views/_rule_drafts_backend.py`:

```python
class RuleSubmissionBackend(Protocol):
    name: str

    def submit_draft(
        self,
        *,
        draft_path: str,
        sml_source: str,
        rule_name: str,
        summary: str,
        author_email: str,
        is_new_rule: bool,
        wire_into_main: bool,
    ) -> SubmissionResult: ...

    def list_pending_drafts(self) -> list[PendingDraft]: ...
```

`SubmissionResult` and `PendingDraft` are backend-neutral dataclasses with a
`title`, optional `url`, and an `extras: dict` for backend-specific fields.
Raise `RuleDraftBackendError(message, status_code)` for any failure path
(missing config, upstream API error, file conflict, etc.); the view layer
surfaces the message and status to the operator.

The `_rule_drafts_github.py` and `_rule_drafts_gitlab.py` modules are working
templates. To add, for example, a Tangled backend:

1. Add `_rule_drafts_tangled.py` next to the existing backend modules with a
   `TangledBackend` class implementing the Protocol.
2. Wire it into `load_backend()` in `_rule_drafts_backend.py`:
   ```python
   if name == 'tangled':
       from ._rule_drafts_tangled import TangledBackend
       return TangledBackend.from_env()
   ```
3. Add the new value to the "unknown backend" error message in the same file
   and to the "no backend configured" message in `_rule_drafts_null.py`.
4. Document its env vars in this file.

Tests for the existing backends in
`osprey_worker/src/osprey/worker/ui_api/osprey/views/tests/test_rule_drafts.py`
mock the upstream HTTP calls with `requests_mock` and assert against the
response shape — a workable pattern for any HTTP-backed adapter.

## Why this is pluggable

Osprey ships the engine and the editor. The submission target is a
deployment concern: different adopters use different VCS hosting, and some
don't use git-as-a-service at all (the `local` backend exists for them). The
Protocol keeps the upstream code free of any one host's assumptions and lets
adopters bring their own integration without changes to the editor or the
view layer.
