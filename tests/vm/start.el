;;; start.el --- Start a terminal in a session, then wait -*- lexical-binding: t; -*-

;; Run as a systemd user service in the VM test.  Writes the session id to
;; /tmp/session-id once the shell has printed its marker, then stays alive
;; until the service is stopped.

(require 'ghostel-mux)
(setq ghostel-shell "/bin/sh"
      ghostel-shell-integration nil)
(ghostel-mux-mode 1)
(let ((buffer (ghostel-create "vm"))
      (deadline (+ (float-time) 30)))
  (with-current-buffer buffer
    (ghostel--send-string "echo before-$((20+1))\n"))
  (while (and (< (float-time) deadline)
              (not (string-match-p
                    "before-21"
                    (with-current-buffer buffer
                      (or (ghostel--copy-all-text ghostel--term) "")))))
    (accept-process-output nil 0.1))
  (write-region (buffer-local-value 'ghostel-mux--id buffer) nil "/tmp/session-id")
  (while t
    (accept-process-output nil 1)))

;;; start.el ends here
