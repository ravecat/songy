default:
    @just --list

[no-exit-message]
[positional-arguments]
mix +args:
    @mix "$@"

[no-exit-message]
[positional-arguments]
[working-directory('assets')]
assets +args:
    @bun run "$@"

setup:
    just mix local.hex --force --if-missing
    just mix local.rebar --force --if-missing
    just mix deps.get
    just assets setup --frozen-lockfile

[arg("erl", long="erl")]
[arg("sname", long="sname")]
[no-exit-message]
up sname="songy" erl="-proto_dist inet6_tcp":
    just setup
    just assets build
    exec watchexec \
        --exit-on-error \
        --restart \
        --watch envs \
        --watch config \
        --watch mix.exs \
        --watch mix.lock \
        --no-vcs-ignore \
        --shell=none \
        --wrap-process=none \
        -- \
        direnv exec . iex \
            --sname "{{ sname }}" \
            --erl "{{ erl }}" \
            -S mix serve

[no-exit-message]
[positional-arguments]
[working-directory('assets')]
storybook *args:
    @bun run storybook "$@"

format:
    mix format
    prettier --write "**/*.md"

check:
    openspec validate --all --strict --no-interactive
    mix format --check-formatted
    mix compile
    mix test
    prettier --check "**/*.md"
    just assets check
    just assets typecheck
    just assets test --reporter=html
    MIX_ENV=prod mix compile
    MIX_ENV=prod just assets deploy
    MIX_ENV=prod mix phx.digest
