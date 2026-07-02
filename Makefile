.PHONY: bench-synthetic bench-synthetic-extreme

bench-synthetic:
	emacs --batch -l ./bench/run-synthetic-benchmark.el

bench-synthetic-extreme:
	ORG_TODOIST_BENCH_PROJECTS=20 \
	ORG_TODOIST_BENCH_SECTIONS_PER_PROJECT=5 \
	ORG_TODOIST_BENCH_TASKS_PER_SECTION=40 \
	ORG_TODOIST_BENCH_COMMENTS_PER_TASK=2 \
	emacs --batch -l ./bench/run-synthetic-benchmark.el
