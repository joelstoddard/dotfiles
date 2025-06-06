SHELL = /bin/bash

.PHONY: clean install

clean:
	@echo "Cleaning up..."
	./uninstall.sh

install:
	@echo "Configuring system..."
	./install.sh
