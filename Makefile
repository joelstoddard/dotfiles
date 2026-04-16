.PHONY: install uninstall generate-theme verify test

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
