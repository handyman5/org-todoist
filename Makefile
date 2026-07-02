EMACS ?= emacs
EMACSFLAGS ?= --batch

.PHONY: bench-synthetic

bench-synthetic:
	$(EMACS) $(EMACSFLAGS) -l ./bench/run-synthetic-benchmark.el
