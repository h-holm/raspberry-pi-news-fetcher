# Run on the Raspberry Pi (or any Debian-like box with GNU tools and bash >= 4.4):
#   sudo apt install shellcheck bats
SHELL := /bin/bash
SCRIPTS := $(wildcard scripts/*.sh scripts/lib/*.sh) tests/fakes/ebook-convert tests/fakes/rclone hooks/pre-commit

.PHONY: check lint test
check: lint test

lint:
	shellcheck -x $(SCRIPTS)

test:
	bats tests/
