.PHONY: format format.check serve

format:
	prettier --write "**/*.md"

format.check:
	prettier --check "**/*.md"

serve:
	iex --sname songy --cookie $$(cat ~/.erlang.cookie) -S mix serve
