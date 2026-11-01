# SPDX-License-Identifier: MIT
#
# libghostty-vt, built by ghostty's own recipe from the ghostty commit that
# ghostel's native module vendors.  The session's copy of the terminal and
# ghostel's must come from the same commit: the snapshot format a session
# writes has no compatibility promise across versions.  The `ghostty-pin`
# check fails when ghostel moves to another commit and this one stays.
{ callPackage, fetchFromGitHub }:
let
  rev = "b2c78c9bd9bc88a16d9c3769b0fb17ddde1b78b1";
  src = fetchFromGitHub {
    owner = "ghostty-org";
    repo = "ghostty";
    inherit rev;
    hash = "sha256-GesLS81douyi/SSegVbd5wmQ7u7+ntGnYVEFpOvgnzU=";
  };
in
(callPackage "${src}/nix/libghostty-vt.nix" {
  optimize = "ReleaseFast";
  revision = builtins.substring 0 7 rev;
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      ghosttyRev = rev;
    };
  })
