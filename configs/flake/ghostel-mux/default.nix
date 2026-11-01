# SPDX-License-Identifier: MIT
{ ... }:
{
  config,
  inputs,
  lib,
  ...
}:
{

  imports = [ inputs.flake-parts.flakeModules.partitions ];

  debug = false;
  caisson = {
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };

    # The packages are the `default` entry of this flake's package overlay
    # registry (pkg-overlays/, registered on mkLib): the package set
    # applies it by default, and the flake exports it as `pkgOverlays` and
    # as the plain `overlays.default`.
    nixpkgs = {
      packages.export.enabled = true;
    };
  };

  perSystem =
    { config, ... }:
    {
      packages.default = config.packages.ghostel-mux;
    };

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = (lib.caisson.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = (lib.caisson.pins.flake-compat ../../../tests/dependencies).sources;
    module =
      { inputs, self, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, system, ... }:
          {
            checks = import ../../../tests/checks.nix {
              inherit pkgs;
              packages = self.packages.${system};
            };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
