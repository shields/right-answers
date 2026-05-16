.PHONY: lint fmt

lint:
	bunx prettier --check '**/*.md'

fmt:
	bunx prettier --write '**/*.md'
