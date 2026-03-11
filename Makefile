SHELL = /bin/bash

.PHONY: clean install generate

clean:
	@echo "Cleaning up..."
	./uninstall.sh
	stow -D .

install:
	@echo "Configuring system..."
	./install.sh
	stow . --adopt -t ~

generate:
	@echo "Generating OS scripts from packages.yaml..."
	python3 scripts/generate.py
