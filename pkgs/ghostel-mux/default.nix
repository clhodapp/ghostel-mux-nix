# SPDX-License-Identifier: MIT
#
# The session program, and ghostel-mux.el with the program's path filled
# in, under share/emacs/site-lisp.  The install check runs the protocol
# tests against the installed program.  SRC is the ghostel-mux source.
{
  lib,
  rustPlatform,
  pkg-config,
  python3,
  libghostty-vt,
  src,
}:
rustPlatform.buildRustPackage {
  pname = "ghostel-mux";
  version = "0.1.0";

  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];
  buildInputs = [ libghostty-vt ];

  postInstall = ''
    install -Dm644 -t $out/share/emacs/site-lisp lisp/ghostel-mux.el lisp/ghostel-mux-evil.el
    substituteInPlace $out/share/emacs/site-lisp/ghostel-mux.el \
      --replace-fail '(defcustom ghostel-mux-program "ghostel-mux"' \
                     "(defcustom ghostel-mux-program \"$out/bin/ghostel-mux\""
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ python3 ];
  installCheckPhase = ''
    runHook preInstallCheck
    GHOSTEL_MUX=$out/bin/ghostel-mux python3 -W ignore test/session_test.py
    runHook postInstallCheck
  '';

  passthru = { inherit libghostty-vt; };

  meta = {
    description = "Ghostel terminals that outlive Emacs";
    license = lib.licenses.mit;
    mainProgram = "ghostel-mux";
    platforms = lib.platforms.linux;
  };
}
