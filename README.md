# Nix Expressions For Firefox Addons

This flake provides about **90,000** addons from https://addons.mozilla.org/ as Nix packages. (with more to come!)

A GitHub Action updates the list every day at 2:37am UTC.

## Declare Firefox Addons With [Home-Manager](https://github.com/nix-community/home-manager)

### With Flakes
(it is assumed that Home Manager is set up)

1. Add this repository as an input to your flake

```nix
{
  inputs = {
    # ...
    nix-firefox-addons.url = "github:osipog/nix-firefox-addons";
  }
  # ...
}
```

(Make sure that `inputs` is exposed to your modules with `specialArgs`)


2. In your `home.nix` (or wherever you configured Firefox) add the desired addons (uBlock Origin as an example)

```nix
{ inputs, pkgs, ... }: {
  # ...
  programs.firefox = {
    enable = true;
    # ...
    profiles.default = {
      extensions = {
        packages = with inputs.nix-firefox-addons.addons.${pkgs.system} [
          ublock-origin
        ];
        settings."uBlock0@raymondhill.net".settings = {
          selectedFilterLists = [
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-unbreak"
            "ublock-quick-fixes"
          ];
        };
      };

      # optional: without this the addons need to be enabled manually after first install
      settings = {
        "extensions.autoDisableScopes" = 0;
      };
    }
  }
}
```

### Without Flakes

TODO

## Getting Addons

To find the package name (slug) and the addon ID (guid) of the addon you want to add to your config, you can use the `search-addon` command of this flake. It takes one argument which is a search query of the addon you are looking for and it returns a list with 10 matching addons with name, slug and guid.

```
nix run github:osipog/nix-firefox-addons#search-addon ublock
```
![image](https://github.com/user-attachments/assets/006b2e45-c71f-47df-b55b-7d352cc818b5)



## Inspiration

- [rycee's NUR expressions](https://gitlab.com/rycee/nur-expressions) containing expressions for Firefox addons
- [montchr's firefox-addons](https://github.com/seadome/firefox-addons) also containing Nix expressions for Firefox addons
- [VSCode extensions Nix expressions by nix-community](https://github.com/nix-community/nix-vscode-extensions) as a rolemodel of scale
