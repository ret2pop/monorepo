(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq enable-local-variables :all)

(defalias (quote yes-or-no-p) (lambda (&rest args) t))
(defalias (quote y-or-n-p) (lambda (&rest args) t))

(setq message-log-max t)
(setq standard-output (quote external-debugging-output))

(princ "STEP 0: tf\n" (quote external-debugging-output))

(setq noninteractive t)
(setq system-email "ci-runner@nullring.xyz")
(setq system-username "ci-runner")
(setq system-fullname "Preston Pan") ;; needed for postamble
(setq system-gpgkey "00000000")
(defun package-vc-install (&rest args) (message "blocked package-vc-install for %s" args))
(defun package-vc--unpack (&rest args) nil)
(setq package-archives nil)
(setq use-package-always-ensure nil)
(setq package-vc-selected-packages nil)

(defalias (quote scroll-bar-mode) (quote ignore))
(defalias (quote tool-bar-mode) (quote ignore))
(defalias (quote menu-bar-mode) (quote ignore))

(provide (quote lean4-mode))
(provide (quote irony-mode))
(provide (quote irony))
(defalias (quote irony-cdb-autosetup-compile-options) (quote ignore))

(setq org-latex-pdf-process '("xelatex -shell-escape -interaction nonstopmode %f"))
(setq org-startup-with-latex-preview nil)
(setq org-startup-indented nil)
(setq org-export-with-latex t)
(setq org-confirm-babel-evaluate nil)
(setq load-prefer-newer t)
(setq gc-cons-threshold 100000000)
(setq vc-handled-backends nil)
(setq make-backup-files nil auto-save-default nil create-lockfiles nil)

(require 'catppuccin-theme)
(setq catppuccin-flavor 'mocha)
(load-theme 'catppuccin t)

(princ "STEP 1: init.el?\n" (quote external-debugging-output))
