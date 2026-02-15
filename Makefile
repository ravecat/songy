.PHONY: format format.check

format:
	prettier --write "**/*.md"

format.check:
	prettier --check "**/*.md"
