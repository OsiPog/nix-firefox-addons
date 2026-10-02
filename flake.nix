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
    inherit (nixpkgs) lib;
    systems = lib.systems.flakeExposed;
      
    inherit (builtins) listToAttrs fromJSON readFile;
    inherit (lib) pipe;
    inherit (lib.strings) splitString;

    addonPackages = pkgs: let
      buildFirefoxXpiAddon = import ./src/lib/build-firefox-xpi-addon.nix pkgs;
    in
      pipe ./addons.jsonl [
        # read all addon data into memory
        readFile
        (splitString "\n")
        (map fromJSON)

        # translate api resource to nix package
        (map buildFirefoxXpiAddon)

        # to attrset with name being the addon slug
        (map (pkg: {
          name = pkg.pname;
          value = pkg;
        }))
        listToAttrs
      ];
  in
    {
      overlays.default = final: prev: {
        firefoxAddons = addonPackages final;
      };
    }
    // (
      flake-utils.lib.eachSystem systems (
        system: let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          addons = (addonPackages pkgs);

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
