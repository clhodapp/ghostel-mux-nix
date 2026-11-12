# ghostel-mux-nix

Nix packaging of [ghostel-mux](https://github.com/clhodapp/ghostel-mux),
terminals for [ghostel](https://github.com/dakra/ghostel) that outlive the
Emacs showing them.

ghostel-mux's session program links libghostty-vt, and its snapshots
restore only into a ghostel whose native module vendors the same ghostty
commit. This flake builds libghostty-vt from that commit with the build
recipe in ghostty, and one of its checks fails when the two commits diverge.

## Use it

The flake exports, under `pkgs.ghostel-mux` through its overlay and as
plain packages:

| Package | What it is |
|---|---|
| `ghostel-mux` | the session program, plus `share/emacs/site-lisp/` holding `ghostel-mux.el`, with the program's path filled in, and `ghostel-mux-evil.el` |
| `ghostel-native-hooks-patch` | the patch to apply to ghostel's native module |
| `libghostty-vt` | libghostty-vt from the ghostty commit ghostel 0.60.0 vendors |

The patch is made against ghostel 0.60.0. In an Emacs package set, patch
ghostel's module and put `share/emacs/site-lisp` of `ghostel-mux` on the
load path:

```nix
ghostel = super.ghostel.overrideAttrs (old: {
  passthru = old.passthru // {
    module = old.passthru.module.overrideAttrs (m: {
      patches = (m.patches or [ ]) ++ [ pkgs.ghostel-mux.ghostel-native-hooks-patch ];
    });
  };
});
```

The ghostel-mux README covers the Emacs side.

## Check it

```sh
nix flake check
```

builds the packages and runs, against ghostel 0.60.0 with the patch
applied:

- the protocol tests, against the installed program;
- the tests of the two ghostel hooks;
- the end-to-end tests in a batch Emacs;
- a NixOS VM test in which an Emacs running as a systemd user service starts
  a terminal, the service is stopped, and another Emacs adopts the terminal;
- the check that libghostty-vt and ghostel use one ghostty commit;
- the formatter.

To check a local ghostel-mux checkout instead of the pinned one:

```sh
nix flake check --override-input ghostel-mux-src path:../ghostel-mux
```
