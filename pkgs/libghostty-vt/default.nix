# SPDX-License-Identifier: MIT
#
# libghostty-vt, built by the build recipe in ghostty from the ghostty commit that
# ghostel's native module vendors.  The session's copy of the terminal and
# ghostel's must come from the same commit: the snapshot format a session
# writes has no compatibility promise across versions.  The `ghostty-pin`
# check fails when ghostel moves to another commit and this one stays.
#
# GHOSTTY-SRC is the `ghostty-src` input.  A flake input is fetched before
# evaluation, so evaluating the recipe it holds builds nothing.
{ callPackage, ghostty-src }:
(callPackage "${ghostty-src}/nix/libghostty-vt.nix" {
  optimize = "ReleaseFast";
  revision = builtins.substring 0 7 ghostty-src.rev;
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      ghosttyRev = ghostty-src.rev;
    };
  })
