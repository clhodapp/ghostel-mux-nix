# SPDX-License-Identifier: MIT
#
# The checks of ghostel-mux-nix: a flake-parts configuration declared
# inside the flake-parts caisson top (configs/flake/ghostel-mux), whose
# dependencies are those of the caisson top with the pins of
# tests/dependencies beside them. The caisson top gathers the checks
# declared here into its `checks` output. A flake that lists
# ghostel-mux-nix as an input reads nothing of this configuration, so it
# locks none of the pins of tests/dependencies.
{ ... }:
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    let
      checks = import ../../../tests/checks.nix {
        inherit pkgs;
        packages = pkgs.ghostel-mux;
      };
    in
    {
      # Duplicated in the formatter partition of
      # configs/flake/ghostel-mux: the partition and this configuration
      # are separate evaluations.
      treefmt.programs.nixfmt.enable = true;

      caisson.checks = {
        treefmt = {
          category = "format";
          description = "the Nix files are formatted with nixfmt";
        };
        ghostty-pin = {
          derivation = checks.ghostty-pin;
          category = "build";
          description = "ghostel vendors the ghostty commit libghostty-vt is built from";
        };
        hooks = {
          derivation = checks.hooks;
          category = "build";
          description = "the ERT tests of the native hooks patch of ghostel pass";
        };
        end-to-end = {
          derivation = checks.end-to-end;
          category = "build";
          description = "the ERT tests of ghostel-mux pass against the built program";
        };
        systemd = {
          derivation = checks.systemd;
          category = "vm";
          description = "a session started with the systemd launcher outlives the Emacs service that started it, and another Emacs adopts it";
        };
      };
    };
}
