This branch adds a reproducible synthetic performance benchmark for `org-todoist` that does not require live Todoist credentials or network access.

Why this exists:

- Upstream performance work is easier to justify when there is a checked-in benchmark that anyone can run.
- Live traces are valuable, but they depend on one user's data set, credentials, and local environment.
- A synthetic harness makes regressions easier to catch and lets reviewers compare branches on the same workload.

What is included:

- `bench/synthetic-benchmark.el`
  - Generates a large synthetic Org Todoist file in a temporary location.
  - Generates a matching fake Todoist sync response in memory.
  - Measures `org-todoist--push` and `org-todoist--parse-response` independently with `benchmark-run`.
  - Prints a compact JSON result so it is easy to compare across commits and branches.

The benchmark does not try to model every real-world detail perfectly. Its purpose is to provide a stable, repeatable workload that exercises the same broad hot paths:

- AST lookup
- property access
- push diff generation
- response parsing
- task/section/project updates
- description and comment handling

Suggested invocation:

```bash
emacs --batch -Q \
  -L /path/to/org-todoist \
  -L /path/to/org \
  -L /path/to/s \
  -L /path/to/dash \
  -L /path/to/ts \
  -l /path/to/org-todoist.el \
  -l /path/to/bench/synthetic-benchmark.el
```

Expected output shape:

```json
{"projects":20,"sections_per_project":5,"tasks_per_section":40,"comments_per_task":2,"push_seconds":...,"parse_seconds":...}
```

This branch is intended to land before the optimization branches so later PRs can cite benchmark deltas from a shared harness.
