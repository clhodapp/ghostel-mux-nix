# SPDX-License-Identifier: MIT
#
# The default package overlay: this flake's packages under
# `pkgs.ghostel-mux` (`.ghostel-mux`, `.libghostty-vt`,
# `.ghostel-native-hooks-patch`). A consumer that lists this flake in
# `projects` holds it as `ghostel-mux/default`, which its package sets
# apply by default. The ghostel-mux source comes from the
# `ghostel-mux-src` input.
{ closure-inputs, closure-lib, ... }:
{
  overlay = closure-lib.caisson.nixpkgs.mkPackagesOverlay (
    { callPackage, ... }:
    import ../../pkgs {
      inherit callPackage;
      src = closure-inputs.ghostel-mux-src;
    }
  ) "ghostel-mux";
}
