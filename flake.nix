{
  description = "Songy dev environment";

  inputs = {
    # Stable channel - update flake.lock quarterly or on critical bugs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        beam = pkgs.beam.packages.erlang_28;
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            beam.erlang
            beam.elixir_1_19
            pkgs.git
            pkgs.glibcLocales
            pkgs.nodePackages.prettier
          ];

          shellHook = ''
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
          '';

          # NOTE: Versions may differ from Dockerfile (hexpm/elixir:1.19.5-erlang-28.3.3)
          # Sync manually when updating either file
        };
      });
}
