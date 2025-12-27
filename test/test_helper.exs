ExUnit.start()
# Database connection disabled - uncomment if needed
# Ecto.Adapters.SQL.Sandbox.mode(Songy.Repo, :manual)

# Load StreamData for property-based testing with TypeCheck
Code.ensure_loaded(StreamData)

Repatch.setup()
