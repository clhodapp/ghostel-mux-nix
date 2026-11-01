# SPDX-License-Identifier: MIT
#
# The patch from the ghostel-mux source (SRC) that adds two hooks to
# ghostel's native module: `ghostel--new-from-snapshot', which builds a
# terminal from a libghostty snapshot, and `ghostel--connect-native-socket',
# which runs ghostel's native reader on a Unix socket in place of a PTY.
# ghostel-mux.el needs both.  A consumer applies it to the module, for
# example:
#
#   ghostel = super.ghostel.overrideAttrs (old: {
#     passthru = old.passthru // {
#       module = old.passthru.module.overrideAttrs (m: {
#         patches = (m.patches or [ ]) ++ [ pkgs.ghostel-mux.ghostel-native-hooks-patch ];
#       });
#     };
#   });
{ runCommand, src }:
runCommand "ghostel-native-hooks.patch" { } ''
  cp ${src}/patches/ghostel-native-hooks.patch $out
''
