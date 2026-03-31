;; ci-runner.el
(load-file (expand-file-name "tests/ci-build.el" default-directory))
(load-file (expand-file-name "init.el" (getenv "NIXMACS_DIR")))
(load-file (expand-file-name "tests/ci-build-stage-two.el" default-directory))
