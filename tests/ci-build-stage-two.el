(princ "STEP 2: init.el.\n" (quote external-debugging-output))

(setq org-id-track-globally t)

(princ "STEP 3: after org roam\n" (quote external-debugging-output))

(setq term-file-prefix nil)

(princ "STEP 4: after org roam\n" (quote external-debugging-output))

(force-mode-line-update)

(setq org-html-link-use-abs-url nil)
(setq default-directory (expand-file-name "~/monorepo"))
(setq org-html-link-use-abs-url nil)
(setq org-html-link-org-files-as-html t)

(require (quote htmlize))
(require (quote nix-mode))

(setq org-html-htmlize-output-type (quote css))

(princ "STEP 5: before catppuccin\n" (quote external-debugging-output))

(require 'catppuccin-theme)
(setq catppuccin-flavor 'mocha)
(load-theme 'catppuccin t)

(defun my-ci-force-fontification ()
  "Ensure the buffer is fully colorized before htmlize touches it."
  (font-lock-ensure)
  (font-lock-flush)
  (font-lock-ensure))

(add-hook 'org-publish-before-export-hook #'my-ci-force-fontification)

(face-spec-recalc 'default (selected-frame))
(when (fboundp 'redisplay) (redisplay t))

(princ (format "THEME CHECK - Default background: %s\n" 
               (face-attribute 'default :background)) 
       'external-debugging-output)

(princ "STEP 6: before publish-all\n" (quote external-debugging-output))

(org-publish-all t)
(org-publish-all nil)
