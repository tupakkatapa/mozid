# 🦊 mozid
A command-line tool and Nix library for retrieving Firefox extension IDs from Mozilla Add-ons using the official API.

This tool was inspired by the difficulty of retrieving the extension ID when non-declarative installations are blocked in Firefox, as discussed in this [thread](https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/17).

## Usage

### As a Nix Library

Add mozid to your flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    mozid.url = "github:tupakkatapa/mozid";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = {
            inherit (inputs) mozid;
          };
        }
      ];
    };
  };
}
```

Then use in your home-manager configuration:

```nix
{
  home-manager.users.youruser = {
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies.ExtensionSettings =
          {
            "*".installation_mode = "blocked";
          }
          // mozid.lib.mkExtensions [
            "vimium-ff"
            "ublock-origin"
            "bitwarden-password-manager"
          ];
      };
    };
  };
}
```

**Alternative:** Use `getExtensionId` for more control:

```nix
{
  home-manager.users.youruser = {
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies.ExtensionSettings = {
          "*".installation_mode = "blocked";

          "${mozid.lib.getExtensionId "vimium-ff"}" = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/vimium-ff/latest.xpi";
            installation_mode = "force_installed";
          };

          "${mozid.lib.getExtensionId "ublock-origin"}" = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
    };
  };
}
```

### As a Command-Line Tool

Run directly with Nix (accepts both slugs and URLs):
```bash
# Using addon slug
nix run github:tupakkatapa/mozid -- vimium-ff
# Output: {d7742d87-e61d-4b78-b8a1-b469842139fa}

# Using full URL
nix run github:tupakkatapa/mozid -- https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
# Output: uBlock0@raymondhill.net
```

### Without Nix

Clone the repository and make the script executable:

```bash
git clone https://github.com/tupakkatapa/mozid.git
cd mozid
chmod +x mozid.sh
./mozid.sh <url>
```

