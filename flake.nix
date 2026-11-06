{
  description = "Development shell for tmc-server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, nixpkgs-ruby, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Keep in step with the image in DockerfileBase; nixpkgs only carries the newest Rubies.
        ruby = nixpkgs-ruby.packages.${system}."ruby-3.3";
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ruby
            pkgs.nodejs
            pkgs.postgresql
            # Without it the pg gem finds the host pg_config and links against the host glibc.
            pkgs.postgresql.pg_config
            pkgs.libyaml
            pkgs.openssl
            pkgs.zlib
            pkgs.libffi
            pkgs.pkg-config
            pkgs.gnumake
            pkgs.vips
            pkgs.git
            pkgs.lefthook
          ];

          shellHook = ''
            # Gems go into the project rather than the Nix store or another Ruby's GEM_HOME.
            export BUNDLE_PATH="$PWD/vendor/bundle"
            export GEM_HOME="$PWD/vendor/bundle/ruby/${ruby.version.libDir}"
            export PATH="$GEM_HOME/bin:$PWD/bin:$PATH"

            # Never in CI or Docker builds.
            if [ -z "''${CI:-}" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              lefthook install >/dev/null
            fi
          '';
        };
      }
    );
}
