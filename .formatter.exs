[
  import_deps: [:ecto, :ecto_sql, :phoenix, :typed_struct],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, Recode.FormatterPlugin],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  line_length: 120,
  locals_without_parens: [
    polymorphic_embeds_one: 2,
    polymorphic_embeds_many: 2
  ]
]
