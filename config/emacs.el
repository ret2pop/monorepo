;; [[file:emacs.org::*VTerm][VTerm:1]]
(use-package vterm
  :custom
  (vterm-kill-buffer-on-exit nil)
  :hook (vterm-exit-functions . rp/vterm-close-window-on-exit))
;; VTerm:1 ends here
