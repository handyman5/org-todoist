.PHONY: bench-synthetic bench-synthetic-extreme

EMACS ?= emacs
BENCH_LOAD = \
	--batch \
	--eval "(require 'package)" \
	--eval "(package-initialize)"
BENCH_BASE = $(EMACS) $(BENCH_LOAD) -l ./org-todoist.el
BENCH_RUN = -l ./bench/synthetic-benchmark.el

bench-synthetic:
	$(BENCH_BASE) $(BENCH_RUN)

bench-synthetic-extreme:
	$(BENCH_BASE) \
	--eval "(setq org-todoist-benchmark-project-count 20 \
	              org-todoist-benchmark-sections-per-project 5 \
	              org-todoist-benchmark-tasks-per-section 40 \
	              org-todoist-benchmark-comments-per-task 2)" \
	$(BENCH_RUN)
