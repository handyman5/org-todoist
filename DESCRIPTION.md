This branch caches each project's default section during response parsing.

The original code repeatedly searched a project subtree for the synthetic default section headline used for unsectioned tasks. On a large file with many imported tasks, that repeated subtree lookup becomes an avoidable O(n) tax.

What changes:

- Adds a per-parse default-section cache keyed by project id.
- Tracks default sections when they are created or updated.
- Uses the cached helper when:
  - ensuring every project has a default section
  - placing unsectioned imported tasks
  - reusing an existing default section under a project

Performance contribution:

- This is a small code change with good leverage because the default-section lookup sits on a hot response-path loop.
- It works together with the AST index and property drawer cache work to reduce the cost of task placement in large projects.
- It did not have a perfectly isolated standalone live trace, but it was part of the step that moved the profiled dirty-sync path down to about `10.8s` total and materially reduced repeated subtree scans during task import.
