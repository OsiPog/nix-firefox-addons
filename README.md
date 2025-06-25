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

2. Import the module into your Home Manager configuration

In your flake's Home Manager configuration:
```nix
{
  outputs = { self, nixpkgs, home-manager, nix-firefox-addons, ... }: {
    homeConfigurations.your-username = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        # your other modules...
        nix-firefox-addons.nixosModules.default
        ./home.nix
      ];
    };
  };
}
```

Alternatively, you can also import it directly in your `home.nix` with:
```nix
{ inputs, ... }: {
  imports = [ inputs.nix-firefox-addons.nixosModules.default ];
  # rest of your configuration...
}
```

3. In your `home.nix` (or wherever you configured Firefox) add the desired addons (uBlock Origin as an example)

```nix
{ pkgs, ... }: {
  # ...
  programs.firefox = {
    enable = true;
    # ...
    profiles.default = {
      extensions = {
        packages = with pkgs.firefoxAddons [
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
![image](https://github.com/user-attachments/assets/86b0fc26-3571-4f0d-9992-af3fc3cffca9)




## Inspiration

- [rycee's NUR expressions](https://gitlab.com/rycee/nur-expressions) containing expressions for Firefox addons
- [montchr's firefox-addons](https://github.com/seadome/firefox-addons) also containing Nix expressions for Firefox addons
- [VSCode extensions Nix expressions by nix-community](https://github.com/nix-community/nix-vscode-extensions) as a rolemodel of scale
