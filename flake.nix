# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #
 {
  # nixpkgs collection
  inputs = {
    nixpkgs.url = "github:flox/nixpkgs/stable";
    nixpkgs-stable.url = "github:flox/nixpkgs/stable";
    nixpkgs-unstable.url = "github:flox/nixpkgs/unstable";
    nixpkgs-staging.url = "github:flox/nixpkgs/staging";
  };

  # Catalogs
  inputs = {
    "nixpkgs__netlify__aarch64-darwin" = {
      url = "github:flox-examples/nixpkgs-netlify/aarch64-darwin";
      flake = false;
    };

    "nixpkgs__netlify__aarch64-linux" = {
      url = "github:flox-examples/nixpkgs-netlify/aarch64-linux";
      flake = false;
    };

    "nixpkgs__netlify__i686-linux" = {
      url = "github:flox-examples/nixpkgs-netlify/i686-linux";
      flake = false;
    };

    "nixpkgs__netlify__x86_64-linux" = {
      url = "github:flox-examples/nixpkgs-netlify/x86_64-linux";
      flake = false;
    };

    "nixpkgs__netlify__x86_64-darwin" = {
      url = "github:flox-examples/nixpkgs-netlify/x86_64-darwin";
      flake = false;
    };
  };

  # Capacitor inputs
  inputs.flox-floxpkgs.url = "github:flox/floxpkgs";

  # Clean up of lockfile to re-use entries
  inputs.flox.url = "git+ssh://git@github.com/flox/flox?ref=latest";

  inputs.flox-floxpkgs.inputs.nixpkgs.follows = "/";
  inputs.flox-floxpkgs.inputs.flox.follows = "flox";
  inputs.nixpkgs.follows = "nixpkgs-stable";

  # bug in Nix cannot support three levels of inputs/inputs/inputs/follows
  inputs.flox-floxpkgs.inputs.capacitor.follows = "capacitor";
  inputs.capacitor.url = "github:flox/capacitor";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs";

  outputs = args @ {flox-floxpkgs, ...}:
    flox-floxpkgs.project args ({
      self,
      inputs,
      systems,
      lib,
      ...
    }: {
      config = {
        systems = ["aarch64-linux" "aarch64-darwin" "i686-linux" "x86_64-linux" "x86_64-darwin"];
        extraPlugins =
          [
          ]
          ++ (builtins.attrValues (builtins.mapAttrs (
              name: catalog:
                inputs.flox-floxpkgs.plugins.catalog {
                  catalogDirectory = catalog;
                  path = [];
                  # Baked in assumption that __<system> only contains that system
                  # TODO: support longer prefixes
                  includePath = [(lib.strings.removePrefix "nixpkgs__netlify__" name)];
                }
            )
              (lib.filterAttrs (name: _: lib.hasPrefix "nixpkgs__netlify__" name) inputs)));
      };

      passthru = {
        lib = inputs.nixpkgs-stable.lib;
        legacyPackages = lib.genAttrs systems (system: let
          stabilities = lib.genAttrs ["stable" "staging" "unstable"] (
            stability:
              (import inputs."nixpkgs-${stability}" {
                config.allowUnfree = true;
                inherit system;
              })
              // {recurseForDerivations = true;}
          );
        in
          # treat nixpkgs input as default nipkgs (following stable, by default)
          (import inputs.nixpkgs {
                config.allowUnfree = true;
                inherit system;
          })
          // stabilities
          // {recurseForDerivations = true;});
        stable.legacyPackages = builtins.mapAttrs (_: v: v.stable) self.legacyPackages;
        unstable.legacyPackages = builtins.mapAttrs (_: v: v.unstable) self.legacyPackages;
        staging.legacyPackages = builtins.mapAttrs (_: v: v.staging) self.legacyPackages;

        __functor = _: import inputs.nixpkgs;
        # __functionArgs = { config = true;  system = true; overlays = true;}; # TODO

      };
    });
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
