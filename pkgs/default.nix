# SPDX-License-Identifier: MIT
#
# SRC is the ghostel-mux source; GHOSTTY-SRC is the ghostty source that
# libghostty-vt is built from.
{
  callPackage,
  src,
  ghostty-src,
}:
let
  libghostty-vt = callPackage ./libghostty-vt { inherit ghostty-src; };
in
{
  inherit libghostty-vt;
  ghostel-mux = callPackage ./ghostel-mux { inherit libghostty-vt src; };
  ghostel-native-hooks-patch = callPackage ./ghostel-native-hooks-patch { inherit src; };
}
