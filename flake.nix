{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    inherit (builtins) listToAttrs fromJSON warn;
    inherit (nixpkgs.lib) pipe;

    addonPackages = pkgs: let
      fromYamlFile = import ./src/lib/from-yaml-file.nix pkgs;
      buildFirefoxXpiAddon = import ./src/lib/build-firefox-xpi-addon.nix pkgs;
    in
      pipe ./addons.yaml [
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
  in
    {
      nixosModules.default = {...}: {
        nixpkgs.overlays = [(final: prev: {
          firefoxAddons = addonPackages final;
        })];
      };
    }
    // (
      flake-utils.lib.eachDefaultSystem (
        system: let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          addons =
            warn "Using the nix-firefox-addons.addons.\${system} is discouraged as unfree packages are enabled by default. Using the NixOS module (nix-firefox-addons.nixosModules.default) will enable an overlay that uses your nixpkgs instance with your nixpkgs configuration to build the addons."
            (addonPackages pkgs);

          packages = {
            search-addon = pkgs.writeShellApplication {
              name = "search-addon";
              runtimeInputs = [pkgs.nushell];
              text = ''nu ${./src/search-addon.nu} "$@"'';
            };
            fetch-addons = pkgs.writeShellApplication {
              name = "fetch-addons";
              runtimeInputs = [pkgs.nushell];
              text = ''nu ${./src/fetch-addons.nu} "$@"'';
            };
          };
        }
      )
    );
}
