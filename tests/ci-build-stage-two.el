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
(require 'hl-line)
(require (quote nix-mode))

(setq org-html-htmlize-output-type (quote css))

(princ "STEP 5: before catppuccin\n" (quote external-debugging-output))

(defun my-ci-force-fontification ()
  "Ensure the buffer is fully colorized before htmlize touches it."
  ;; Do NOT try to syntax-highlight the Frankenstein RSS file
  (unless (string-match-p "rss\\.org$" (buffer-file-name))
    (font-lock-ensure)))

(princ "after ci force fontification\n" (quote external-debugging-output))
(princ "C\n" 'external-debugging-output)

(add-hook 'org-publish-before-export-hook #'my-ci-force-fontification)
(princ "C\n" 'external-debugging-output)

(princ "please work\n" (quote external-debugging-output))

(face-spec-recalc 'default (selected-frame))
(princ "please work part 2\n" (quote external-debugging-output))
;; (when (fboundp 'redisplay) (redisplay t))
(princ "please work part 3\n" (quote external-debugging-output))

(princ (format "THEME CHECK - Default background: %s\n" 
               (face-attribute 'default :background)) 
       'external-debugging-output)

(princ "STEP 6: before publish-all\n" (quote external-debugging-output))

(setq treesit-auto-install nil)

;; --- DUMP LOG BUFFERS ---
(let ((warnings-buf (get-buffer "*Warnings*"))
      (messages-buf (get-buffer "*Messages*")))
  
  (princ "\n========================================\n" 'external-debugging-output)
  
  ;; 1. Dump Warnings
  (if warnings-buf
      (with-current-buffer warnings-buf
        (princ "       DUMPING *Warnings* BUFFER        \n" 'external-debugging-output)
        (princ "----------------------------------------\n" 'external-debugging-output)
        (princ (buffer-string) 'external-debugging-output))
    (princ "       No *Warnings* buffer found.      \n" 'external-debugging-output))
    
  (princ "\n========================================\n" 'external-debugging-output)

  ;; 2. Dump Messages
  (if messages-buf
      (with-current-buffer messages-buf
        (princ "       DUMPING *Messages* BUFFER        \n" 'external-debugging-output)
        (princ "----------------------------------------\n" 'external-debugging-output)
        (princ (buffer-string) 'external-debugging-output))
    (princ "       No *Messages* buffer found.      \n" 'external-debugging-output))

  (princ "========================================\n\n" 'external-debugging-output))
;; ----------------------------

(require 'pp) ; Pull in the pretty-printer

(princ "\n========================================\n" 'external-debugging-output)
(princ "   DUMPING org-publish-project-alist    \n" 'external-debugging-output)
(princ "----------------------------------------\n" 'external-debugging-output)

;; pp-to-string formats the nested list with proper indentation and line breaks
(princ (pp-to-string org-publish-project-alist) 'external-debugging-output)

(princ "\n========================================\n\n" 'external-debugging-output)
(setq org-export-use-babel nil)

(advice-add 'org-publish-file :before
            (lambda (file &rest _)
              (princ (format "-> Exporting file: %s\n" file) 'external-debugging-output)))

(advice-add 'org-publish-find-title :before
            (lambda (file &rest _)
              (princ (format "-> Extracting title for sitemap: %s\n" file) 'external-debugging-output)))

(advice-add 'org-publish-file :after
            (lambda (file &rest _)
              (princ (format "<- Finished file: %s\n" file) 'external-debugging-output)))

(defvar my-sitemap-counter 0)
(advice-add 'org-sitemap-format-entry-xml :before
            (lambda (entry &rest _)
              (setq my-sitemap-counter (1+ my-sitemap-counter))
              (when (= 0 (mod my-sitemap-counter 20))
                (princ (format "  [Sitemap XML] Processed %d files... Current: %s\n" 
                               my-sitemap-counter entry) 
                       'external-debugging-output))))

(advice-add 'org-rss-publish-to-rss :around
            (lambda (fn plist filename pub-dir)
              (princ (format "[rss] enter %s\n" filename) 'external-debugging-output)
              (prog1 (funcall fn plist filename pub-dir)
                (princ (format "[rss] leave %s\n" filename) 'external-debugging-output))))

(advice-add 'org-icalendar-create-uid :before
            (lambda (&rest _) (princ "[rss] before uid\n" 'external-debugging-output)))

(advice-add 'org-rss-add-pubdate-property :before
            (lambda (&rest _) (princ "[rss] before pubdate\n" 'external-debugging-output)))

(advice-add 'write-file :before
            (lambda (&rest _) (princ "[rss] before write-file\n" 'external-debugging-output)))

(advice-add 'org-export-to-file :before
            (lambda (&rest _) (princ "[rss] before org-export-to-file\n" 'external-debugging-output)))

(org-publish-all t)
