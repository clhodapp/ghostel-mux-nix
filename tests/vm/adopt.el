;;; adopt.el --- Adopt the session start.el left behind -*- lexical-binding: t; -*-

;; Prints ADOPTED when the adopted terminal shows the output from before and
;; runs a new command.

(require 'ghostel-mux)
(setq ghostel-shell "/bin/sh"
      ghostel-shell-integration nil
      ghostel-query-before-killing nil)
(ghostel-mux-mode 1)

(defun adopt--text (buffer)
  (with-current-buffer buffer
    (or (ghostel--copy-all-text ghostel--term) "")))

(let* ((id (with-temp-buffer
             (insert-file-contents "/tmp/session-id")
             (string-trim (buffer-string))))
       (buffer (ghostel-mux-adopt id))
       (deadline (+ (float-time) 30)))
  (unless (string-match-p "before-21" (adopt--text buffer))
    (error "The adopted terminal lacks the earlier output: %S" (adopt--text buffer)))
  (with-current-buffer buffer
    (ghostel--send-string "echo after-$((20+2))\n"))
  (while (and (< (float-time) deadline)
              (not (string-match-p "after-22" (adopt--text buffer))))
    (accept-process-output nil 0.1))
  (unless (string-match-p "after-22" (adopt--text buffer))
    (error "The adopted terminal did not run a command: %S" (adopt--text buffer)))
  (kill-buffer buffer)
  (princ "ADOPTED\n"))

;;; adopt.el ends here
