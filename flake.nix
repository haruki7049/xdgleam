{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:edolstra/flake-compat";
    nix-gleam.url = "github:arnarg/nix-gleam";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        let
          app = pkgs.buildGleamApplication {
            src = lib.cleanSource ./.;
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.nix-gleam.overlays.default
            ];
          };

          treefmt = {
            projectRootFile = ".git/config";

            # Nix
            programs.nixfmt.enable = true;

            # Gleam
            programs.gleam.enable = true;

            # TOML
            programs.taplo.enable = true;
            settings.formatter.taplo.excludes = [
              "manifest.toml"
              "*/manifest.toml"
            ];

            # GitHub Actions
            programs.actionlint.enable = true;

            # Markdown
            programs.mdformat.enable = true;

            # ShellScript
            programs.shellcheck.enable = true;
            programs.shfmt.enable = true;
          };

          packages = {
            inherit app;
            default = app;
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              # Nix LSP
              pkgs.nil

              # Gleam-lang
              pkgs.gleam
              pkgs.erlang
              #pkgs.rebar3
              #pkgs.elixir
              #pkgs.deno
            ];
          };
        };
    };
}
