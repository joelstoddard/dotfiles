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

test-unit:
	@if [ -x .venv/bin/python ]; then \
		.venv/bin/python -m unittest discover -s test/unit -v; \
	else \
		python3 -m unittest discover -s test/unit -v; \
	fi

test-e2e-local:
	HOME=$$(mktemp -d) ./test/e2e/e2e.sh
