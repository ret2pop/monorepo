(condition-case err
    (progn
      (load-file (expand-file-name "tests/ci-build.el" default-directory))
      (load-file (expand-file-name "init.el" (getenv "NIXMACS_DIR")))
      (load-file (expand-file-name "tests/ci-build-stage-two.el" default-directory))
      (kill-emacs 0))
  (error
   (princ (format "\nFATAL CI ERROR: %s\n" (error-message-string err)) 'external-debugging-output)
   (kill-emacs 1)))
