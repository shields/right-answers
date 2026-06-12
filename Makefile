.PHONY: lint fmt

lint:
	bunx prettier --check .
	bunx tsc
	bunx eslint .

fmt:
	bunx prettier --write .
	bunx eslint --fix .
