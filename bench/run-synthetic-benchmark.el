(setq load-path (cons (file-name-directory (directory-file-name default-directory))
                      load-path))

(setq org-todoist-benchmark-skip-auto-run t)

(load-file (expand-file-name "org-todoist.el" default-directory))
(load-file (expand-file-name "bench/synthetic-benchmark.el" default-directory))

(let ((projects (getenv "ORG_TODOIST_BENCH_PROJECTS"))
      (sections (getenv "ORG_TODOIST_BENCH_SECTIONS_PER_PROJECT"))
      (tasks (getenv "ORG_TODOIST_BENCH_TASKS_PER_SECTION"))
      (comments (getenv "ORG_TODOIST_BENCH_COMMENTS_PER_TASK")))
  (when projects
    (setq org-todoist-benchmark-project-count (string-to-number projects)))
  (when sections
    (setq org-todoist-benchmark-sections-per-project (string-to-number sections)))
  (when tasks
    (setq org-todoist-benchmark-tasks-per-section (string-to-number tasks)))
  (when comments
    (setq org-todoist-benchmark-comments-per-task (string-to-number comments))))

(org-todoist-benchmark-run)
