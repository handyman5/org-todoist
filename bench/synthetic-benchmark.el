;;; synthetic-benchmark.el --- Synthetic org-todoist benchmark -*- lexical-binding: t; -*-

(require 'benchmark)
(require 'json)
(require 'org-todoist)

(defvar org-todoist-benchmark-project-count 15
  "Number of synthetic projects to generate.")

(defvar org-todoist-benchmark-sections-per-project 4
  "Number of synthetic sections to generate per project.")

(defvar org-todoist-benchmark-tasks-per-section 18
  "Number of synthetic tasks to generate per section.")

(defvar org-todoist-benchmark-comments-per-task 1
  "Number of synthetic comments to generate per task.")

(defvar org-todoist-benchmark-show-progress noninteractive
  "Whether the synthetic benchmark should print phase progress updates.")

(defun org-todoist-benchmark--progress (fmt &rest args)
  "Print a benchmark progress message built from FMT and ARGS."
  (when org-todoist-benchmark-show-progress
    (princ (apply #'format (concat "[org-todoist-bench] " fmt "\n") args)
           'external-debugging-output)))

(defun org-todoist-benchmark--headline (level title props &optional todo)
  (concat (make-string level ?*)
          " "
          (if todo (concat todo " ") "")
          title
          "\n:PROPERTIES:\n"
          (mapconcat (lambda (kv) (format ":%s: %s" (car kv) (cdr kv))) props "\n")
          "\n:END:\n"))

(defun org-todoist-benchmark--org-string ()
  (let ((chunks (list "#+title: Todoist\n#+STARTUP: hidedrawers\n")))
    (dotimes (project org-todoist-benchmark-project-count)
      (push (org-todoist-benchmark--headline
             1
             (format "Project %02d" project)
             `(("TODOIST_TYPE" . "PROJECT")
               ("tid" . ,(format "project-%02d" project))))
            chunks)
      (dotimes (section org-todoist-benchmark-sections-per-project)
        (push (org-todoist-benchmark--headline
               2
               (format "Section %02d-%02d" project section)
               `(("TODOIST_TYPE" . "SECTION")
                 ("tid" . ,(format "section-%02d-%02d" project section))))
              chunks)
        (dotimes (task org-todoist-benchmark-tasks-per-section)
          (let ((task-id (format "task-%02d-%02d-%04d" project section task)))
            (push (org-todoist-benchmark--headline
                   3
                   (format "Task %02d-%02d-%04d" project section task)
                   `(("TODOIST_TYPE" . "TASK")
                     ("tid" . ,task-id)
                     ("priority" . "1"))
                   "TODO")
                  chunks)
            (push (format "Synthetic description for %s.\n\n" task-id) chunks)))))
    (apply #'concat (nreverse chunks))))

(defun org-todoist-benchmark--response ()
  (let (projects sections items notes)
    (dotimes (project org-todoist-benchmark-project-count)
      (let ((project-id (format "project-%02d" project)))
        (push `((id . ,project-id)
                (name . ,(format "Project %02d" project)))
              projects)
        (dotimes (section org-todoist-benchmark-sections-per-project)
          (let ((section-id (format "section-%02d-%02d" project section)))
            (push `((id . ,section-id)
                    (project_id . ,project-id)
                    (name . ,(format "Section %02d-%02d" project section)))
                  sections)
            (dotimes (task org-todoist-benchmark-tasks-per-section)
              (let ((task-id (format "task-%02d-%02d-%04d" project section task)))
                (push `((id . ,task-id)
                        (project_id . ,project-id)
                        (section_id . ,section-id)
                        (content . ,(format "Task %02d-%02d-%04d" project section task))
                        (description . ,(format "Synthetic description for %s." task-id))
                        (priority . 1)
                        (labels . [])
                        (checked . :json-false)
                        (is_deleted . :json-false))
                      items)
                (dotimes (comment org-todoist-benchmark-comments-per-task)
                  (push `((item_id . ,task-id)
                          (content . ,(format "Comment %d on %s" comment task-id))
                          (posted_at . "2026-07-01T00:00:00.0Z"))
                        notes))))))))
    `((items . ,(vconcat (nreverse items)))
      (projects . ,(vconcat (nreverse projects)))
      (sections . ,(vconcat (nreverse sections)))
      (collaborators . ,[])
      (notes . ,(vconcat (nreverse notes)))
      (temp_id_mapping . nil)
      (sync_token . "synthetic-token"))))

(defun org-todoist-benchmark-run ()
  "Run a synthetic org-todoist benchmark and print the results."
  (let* ((org-todoist-storage-dir (make-temp-file "org-todoist-bench-state-" t))
         (org-todoist-file (make-temp-file "org-todoist-bench-" nil ".org"))
         (started-at (float-time))
         baseline
         response
         ast
         phase-start
         push-time
         parse-time)
    (unwind-protect
        (progn
         (org-todoist-benchmark--progress
           "starting workload: %d projects, %d sections/project, %d tasks/section, %d comments/task (%d tasks, %d comments total)"
           org-todoist-benchmark-project-count
           org-todoist-benchmark-sections-per-project
           org-todoist-benchmark-tasks-per-section
           org-todoist-benchmark-comments-per-task
           (* org-todoist-benchmark-project-count
              org-todoist-benchmark-sections-per-project
              org-todoist-benchmark-tasks-per-section)
           (* org-todoist-benchmark-project-count
              org-todoist-benchmark-sections-per-project
              org-todoist-benchmark-tasks-per-section
              org-todoist-benchmark-comments-per-task))
          (setq phase-start (float-time))
          (org-todoist-benchmark--progress "[1/4] generating synthetic org and response payloads")
          (setq baseline (org-todoist-benchmark--org-string))
          (setq response (org-todoist-benchmark--response))
          (org-todoist-benchmark--progress
           "[1/4] done in %s"
           (format "%.3fs" (- (float-time) phase-start)))
          (with-temp-file org-todoist-file
            (insert baseline))
          (with-temp-file (expand-file-name "SYNC-BUFFER" org-todoist-storage-dir)
            (insert baseline))
          (setq phase-start (float-time))
          (org-todoist-benchmark--progress "[2/4] parsing org file into an AST")
          (setq ast (org-todoist--file-ast))
          (org-todoist-benchmark--progress
           "[2/4] done in %s"
           (format "%.3fs" (- (float-time) phase-start)))
          (setq phase-start (float-time))
          (org-todoist-benchmark--progress "[3/4] benchmarking push generation")
          (setq push-time
                (benchmark-run 1
                  (org-todoist--push ast (org-todoist--get-last-sync-buffer-ast))))
          (org-todoist-benchmark--progress
           "[3/4] done in %s"
           (format "%.3fs" (car push-time)))
          (setq phase-start (float-time))
          (org-todoist-benchmark--progress "[4/4] benchmarking response parsing")
          (setq parse-time
                (benchmark-run 1
                  (org-todoist--parse-response response ast)))
          (org-todoist-benchmark--progress
           "[4/4] done in %s"
           (format "%.3fs" (car parse-time)))
          (org-todoist-benchmark--progress
           "finished in %s total"
           (format "%.3fs" (- (float-time) started-at)))
          (princ
           (json-encode
            `((projects . ,org-todoist-benchmark-project-count)
              (sections_per_project . ,org-todoist-benchmark-sections-per-project)
              (tasks_per_section . ,org-todoist-benchmark-tasks-per-section)
              (comments_per_task . ,org-todoist-benchmark-comments-per-task)
              (push_seconds . ,(car push-time))
              (parse_seconds . ,(car parse-time))
              (push_gc_runs . ,(nth 1 push-time))
              (parse_gc_runs . ,(nth 1 parse-time)))))
          (princ "\n"))
      (ignore-errors (delete-file org-todoist-file))
      (ignore-errors (delete-directory org-todoist-storage-dir t)))))

(when noninteractive
  (org-todoist-benchmark-run))
