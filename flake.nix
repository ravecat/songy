{
  description = "Songy dev environment";

  inputs = {
    # Stable channel - update flake.lock quarterly or on critical bugs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        beam = pkgs.beam.packages.erlang_27;
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            beam.erlang
            beam.elixir_1_18
            pkgs.git
            pkgs.glibcLocales
          ];

          shellHook = ''
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
          '';

          # NOTE: Versions may differ from Dockerfile (hexpm/elixir:1.18.4-erlang-27.3.3)
          # Sync manually when updating either file
        };
      });
}
