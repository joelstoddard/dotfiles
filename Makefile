SHELL = /bin/bash

.PHONY: clean install

clean:
	@echo "Cleaning up..."
	./uninstall.sh
	stow -D .

install:
	@echo "Configuring system..."
	./install.sh
	stow . --adopt -t ~
