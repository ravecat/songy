{
  description = "Songy dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        beam = pkgs.beam.packages.erlang_28;
        fontsConf = pkgs.writeText "playwright-fonts.conf" ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <dir>${pkgs.noto-fonts}/share/fonts/noto</dir>
            <dir>${pkgs.liberation_ttf}/share/fonts/truetype</dir>
            <alias binding="strong"><family>sans</family><prefer><family>Noto Sans</family></prefer></alias>
            <alias binding="strong"><family>system</family><prefer><family>Noto Sans</family></prefer></alias>
            <alias binding="strong"><family>serif</family><prefer><family>Noto Serif</family></prefer></alias>
            <alias binding="strong"><family>monospace</family><prefer><family>Noto Sans Mono</family></prefer></alias>
            <alias binding="strong"><family>Arial</family><prefer><family>Liberation Sans</family></prefer></alias>
            <alias binding="strong"><family>Times New Roman</family><prefer><family>Liberation Serif</family></prefer></alias>
            <cachedir prefix="xdg">fontconfig</cachedir>
          </fontconfig>
        '';
        playwright = (pkgs.callPackage "${nixpkgs}/pkgs/development/web/playwright/driver.nix" {
          makeFontsConf = _: fontsConf;
        }).playwright-core;
        browsers =
          assert pkgs.lib.assertMsg
            (playwright.version == (builtins.fromJSON (builtins.readFile ./assets/package.json)).devDependencies."@playwright/test")
            "The Nix browser package must match the Playwright version in assets/package.json.";
          playwright.selectBrowsers {
            withFirefox = false;
            withWebkit = false;
            withFfmpeg = false;
          };
      in {
        devShells.default = pkgs.mkShell {
          PLAYWRIGHT_BROWSERS_PATH = "${browsers}";
          FONTCONFIG_FILE = "${fontsConf}";
          packages = [
            beam.erlang
            beam.elixir_1_20
            pkgs.git
            pkgs.bun
            pkgs.direnv
            pkgs.just
            pkgs.nodejs_24
            pkgs.openspec
            pkgs.watchexec
            pkgs.gnumake
            pkgs.stdenv.cc
            pkgs.prettier
          ];

          shellHook = ''
            export LANG=${if pkgs.stdenv.isLinux then "C.UTF-8" else "en_US.UTF-8"}
            export LANGUAGE=C
            export LC_ALL="$LANG"
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
          '';
        };
      });
}
