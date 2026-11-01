# SPDX-License-Identifier: MIT
#
# SRC is the ghostel-mux source.
{ callPackage, src }:
let
  libghostty-vt = callPackage ./libghostty-vt { };
in
{
  inherit libghostty-vt;
  ghostel-mux = callPackage ./ghostel-mux { inherit libghostty-vt src; };
  ghostel-native-hooks-patch = callPackage ./ghostel-native-hooks-patch { inherit src; };
}
