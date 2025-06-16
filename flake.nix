{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (builtins) listToAttrs fromJSON;
        inherit (pkgs.lib) pipe;
        inherit (pkgs) writeShellApplication;

        fromYamlFile = import ./src/lib/from-yaml-file.nix pkgs;
        buildFirefoxXpiAddon = import ./src/lib/build-firefox-xpi-addon.nix pkgs;
      in {
        packages = {
          search-addon = writeShellApplication {
            name = "search-addon";
            runtimeInputs = [pkgs.nushell];
            text = ''nu ${./src/search-addon.nu} "$@"'';
          };
          fetch-addons = writeShellApplication {
            name = "fetch-addons";
            runtimeInputs = [pkgs.nushell];
            text = ''nu ${./src/fetch-addons.nu} "$@"'';
          };
        };

        addons = pipe ./addons.yaml [
          # read all addon data into memory
          fromYamlFile

          # we now have a list of strings containing json
          (map fromJSON)

          # translate api resource to nix package
          (map (addon:
            buildFirefoxXpiAddon {
              guid = addon.g;
              slug = addon.s;
              version = addon.v;
              url = addon.u;
              hash = addon.h;
              permissions = addon.p;
              license = addon.l;
            }))

          # to attrset with name being the addon slug
          (map (pkg: {
            name = pkg.pname;
            value = pkg;
          }))
          listToAttrs
        ];
      }
    );
}
