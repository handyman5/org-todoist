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
  - Prints coarse phase progress in batch mode so long runs do not look hung.
- `bench/run-synthetic-benchmark.el`
  - Loads the package and benchmark harness in batch mode.
  - Initializes installed packages first so normal Emacs package dependencies such as `s`, `dash`, and `ts` are available.
  - Allows workload sizing overrides via environment variables.
- `Makefile`
  - Adds a `bench-synthetic` target sized for routine iteration.
  - Adds a `bench-synthetic-full` target for a larger stress workload.

The benchmark does not try to model every real-world detail perfectly. Its purpose is to provide a stable, repeatable workload that exercises the same broad hot paths:

- AST lookup
- property access
- push diff generation
- response parsing
- task/section/project updates
- description and comment handling

Suggested invocation:

```bash
make bench-synthetic
```

Default workload:

- `15` projects
- `4` sections per project
- `18` tasks per section
- `1` comment per task

That default is intended to be large enough for an iteration-scale run in roughly the 1-2 minute range, while still being practical for repeated local benchmarking.

Optional workload overrides:

```bash
ORG_TODOIST_BENCH_PROJECTS=40 \
ORG_TODOIST_BENCH_SECTIONS_PER_PROJECT=8 \
ORG_TODOIST_BENCH_TASKS_PER_SECTION=60 \
ORG_TODOIST_BENCH_COMMENTS_PER_TASK=3 \
make bench-synthetic
```

To run the larger stress preset:

```bash
make bench-synthetic-full
```

Expected output shape:

```json
{"projects":15,"sections_per_project":4,"tasks_per_section":18,"comments_per_task":1,"push_seconds":...,"parse_seconds":...}
```

This branch is intended to land before the optimization branches so later PRs can cite benchmark deltas from a shared harness.
