.PHONY: install uninstall generate-theme generate-completions verify test test-unit test-e2e-local

install:
	./install.sh

uninstall:
	./uninstall.sh

generate-theme:
	python3 scripts/generate_theme.py

generate-completions:
	python3 scripts/generate_completions.py

verify:
	python3 scripts/verify.py

test:
	python3 test/run_tests.py

PYTHON := $(shell [ -x .venv/bin/python ] && echo .venv/bin/python || echo python3)

test-unit:
	$(PYTHON) -m unittest discover -s test/unit -t . -v

test-e2e-local:
	HOME=$$(mktemp -d) ./test/e2e/e2e.sh
