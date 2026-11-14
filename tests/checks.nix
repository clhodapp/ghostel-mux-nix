# SPDX-License-Identifier: MIT
#
# The flake's checks beside the package checks caisson gathers
# (configs/flake/checks).  PACKAGES are this flake's packages for the system;
# PKGS supplies Emacs and the ghostel the patch is tested against.  The
# test suites come from the ghostel-mux source, `ghostel-mux.src`.
{ pkgs, packages }:
let
  inherit (packages) ghostel-mux libghostty-vt ghostel-native-hooks-patch;

  # The ghostel release whose native module vendors the ghostty commit
  # libghostty-vt is built from, with the hooks patch applied.  The pinned
  # nixpkgs packages an older release, so the source, the Zig toolchain and
  # the Zig dependencies are overridden here.
  ghostel = pkgs.emacsPackages.ghostel.overrideAttrs (
    finalAttrs: old: {
      version = "0.60.0";
      src = pkgs.fetchFromGitHub {
        owner = "dakra";
        repo = "ghostel";
        tag = "v0.60.0";
        hash = "sha256-k10nzaIHKGvPJoI1KiiDBY6yDTKL2OAXZ1kxx91BB3E=";
      };
      zig = pkgs.zig_0_17;
      zigDeps = finalAttrs.zig.fetchDeps {
        inherit (finalAttrs) src pname version;
        fetchAll = true;
        hash = "sha256-Kt3r1B/5kgjMO89gih/87oEtuWmby9NB6oQp5t0vUYw=";
      };
      passthru = old.passthru // {
        module = old.passthru.module.overrideAttrs (m: {
          inherit (finalAttrs)
            src
            version
            zig
            zigDeps
            ;
          patches = (m.patches or [ ]) ++ [ ghostel-native-hooks-patch ];
        });
      };
    }
  );

  # Evil is there for the test of the session list's Evil bindings.
  emacs = pkgs.emacs-nox.pkgs.withPackages (epkgs: [
    ghostel
    epkgs.evil
  ]);

  mksnap =
    pkgs.runCommandCC "mksnap"
      {
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ libghostty-vt ];
      }
      ''
        mkdir -p $out/bin
        cc -o $out/bin/mksnap ${ghostel-mux.src}/test/hooks/mksnap.c $(pkg-config --cflags --libs libghostty-vt)
      '';

  # A batch Emacs run: the test files, a private runtime directory, and a
  # pass/fail result.
  ertCheck =
    name: script:
    pkgs.runCommand name
      {
        nativeBuildInputs = [
          emacs
          pkgs.python3
        ];
      }
      ''
        export HOME=$TMPDIR
        export XDG_RUNTIME_DIR=$TMPDIR/runtime
        mkdir -m 700 $XDG_RUNTIME_DIR
        cp -r ${ghostel-mux.src}/test test
        chmod -R u+w test
        ${script}
        touch $out
      '';

  lisp = "${ghostel-mux}/share/emacs/site-lisp";
in
{
  # The session's terminal and ghostel's must come from one ghostty commit.
  ghostty-pin = pkgs.runCommand "ghostty-pin" { } ''
    if ! grep -q "ghostty/archive/${libghostty-vt.ghosttyRev}.tar.gz" ${ghostel.src}/build.zig.zon; then
      echo "ghostel vendors another ghostty commit than libghostty-vt (${libghostty-vt.ghosttyRev}):" >&2
      grep 'ghostty/archive' ${ghostel.src}/build.zig.zon >&2
      exit 1
    fi
    touch $out
  '';

  hooks = ertCheck "ghostel-hooks" ''
    ${mksnap}/bin/mksnap test/hooks/fixture.snap
    emacs --batch -l test/hooks/hooks-test.el -f ert-run-tests-batch-and-exit
  '';

  end-to-end = ertCheck "ghostel-mux-end-to-end" ''
    export GHOSTEL_MUX=${ghostel-mux}/bin/ghostel-mux
    emacs --batch -L ${lisp} \
      -l test/ghostel-mux-test.el -f ert-run-tests-batch-and-exit
  '';

  # An Emacs running as a systemd user service starts a terminal; stopping
  # that service, as a daemon rotation does, leaves the session running,
  # and another Emacs adopts it.  With the fork launcher, the session is in
  # the service's cgroup and dies with it, which is what the systemd
  # launcher is for.
  systemd = pkgs.testers.runNixOSTest {
    name = "ghostel-mux-systemd";
    nodes.machine = {
      users.users.alice = {
        isNormalUser = true;
        uid = 1000;
        linger = true;
      };
      environment.systemPackages = [
        emacs
        ghostel-mux
      ];
      virtualisation.memorySize = 2048;
    };
    testScript = ''
      import json
      import shlex

      def user(cmd):
          return machine.succeed(
              "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 sh -c "
              + shlex.quote(cmd)
          )

      def sessions():
          return json.loads(user("ghostel-mux list --json"))

      def session(sid):
          return next((s for s in sessions() if s["id"] == sid), None)

      def start_in_service(unit, launcher):
          machine.succeed("rm -f /tmp/session-id")
          user(
              f"systemd-run --user --unit={unit} --setenv=GHOSTEL_MUX_LAUNCHER={launcher} "
              + "--setenv=PATH=/run/current-system/sw/bin "
              + "emacs --batch -L ${lisp} -l ${./vm/start.el}"
          )
          machine.wait_until_succeeds("test -s /tmp/session-id", timeout=60)
          return machine.succeed("cat /tmp/session-id").strip()

      machine.wait_for_unit("user@1000.service")

      with subtest("a session outlives the Emacs service that started it"):
          sid = start_in_service("fake-emacs-a", "systemd")
          user(f"systemctl --user is-active ghostel-mux-{sid}.service")
          assert session(sid)["owner"] is not None, session(sid)
          user("systemctl --user stop fake-emacs-a.service")
          user(f"systemctl --user is-active ghostel-mux-{sid}.service")
          machine.wait_until_succeeds(
              "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 "
              + f"sh -c 'ghostel-mux info {sid}' | grep -q '\"owner\":null'",
              timeout=10,
          )
          assert session(sid)["exit_status"] is None, session(sid)

      with subtest("another Emacs adopts it with its output"):
          out = user("emacs --batch -L ${lisp} -l ${./vm/adopt.el} 2>&1")
          assert "ADOPTED" in out, out
          machine.wait_until_fails(
              "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 "
              + f"systemctl --user is-active ghostel-mux-{sid}.service",
              timeout=15,
          )

      with subtest("with the fork launcher the session dies with the service"):
          sid = start_in_service("fake-emacs-b", "fork")
          assert session(sid) is not None
          user("systemctl --user stop fake-emacs-b.service")
          machine.wait_until_succeeds(
              "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 "
              + f"sh -c 'ghostel-mux list --json' | grep -vq {sid}",
              timeout=10,
          )
          assert session(sid) is None, session(sid)
    '';
  };
}
