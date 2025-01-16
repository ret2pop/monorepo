{ lib, config, pkgs, ... }:
{
  programs.emacs = 
    {
      enable = true;
      package = pkgs.emacs29-pgtk;
      extraConfig = ''
      (setq debug-on-error t)
      (org-babel-load-file
        (expand-file-name "~/monorepo/config/emacs.org"))'';
      extraPackages = epkgs: [
        epkgs.all-the-icons
        epkgs.auctex
        epkgs.catppuccin-theme
        epkgs.chatgpt-shell
        epkgs.company
        epkgs.company-solidity
        epkgs.counsel
        epkgs.dashboard
        epkgs.doom-modeline
        epkgs.elfeed
        epkgs.elfeed-org
        epkgs.elfeed-tube
        epkgs.elfeed-tube-mpv
        epkgs.ellama
        epkgs.elpher
        epkgs.ement
        epkgs.emmet-mode
        epkgs.emms
        epkgs.enwc
        epkgs.evil
        epkgs.evil-collection
        epkgs.evil-commentary
        epkgs.evil-org
        epkgs.f
        epkgs.flycheck
        epkgs.general
        epkgs.gptel
        epkgs.gruvbox-theme
        epkgs.htmlize
        epkgs.irony-eldoc
        epkgs.ivy
        epkgs.ivy-pass
        epkgs.latex-preview-pane
        epkgs.lsp-ivy
        epkgs.lsp-mode
        epkgs.lyrics-fetcher
        epkgs.magit
        epkgs.magit-delta
        epkgs.mu4e
        epkgs.nix-mode
        epkgs.org-fragtog
        epkgs.org-journal
        epkgs.org-roam
        epkgs.org-roam-ui
        epkgs.org-superstar
        epkgs.page-break-lines
        epkgs.password-store
        epkgs.pdf-tools
        epkgs.pinentry
        epkgs.platformio-mode
        epkgs.projectile
        epkgs.rustic
        epkgs.scad-mode
        epkgs.simple-httpd
        epkgs.solidity-flycheck
        epkgs.solidity-mode
        epkgs.sudo-edit
        epkgs.treemacs
        epkgs.treemacs-evil
        epkgs.treemacs-magit
        epkgs.treemacs-projectile
        epkgs.treesit-auto
        epkgs.typescript-mode
        epkgs.unicode-fonts
        epkgs.use-package
        epkgs.vterm
        epkgs.web-mode
        epkgs.websocket
        epkgs.which-key
        epkgs.writegood-mode
        epkgs.writeroom-mode
        epkgs.yaml-mode
        epkgs.yasnippet
        epkgs.yasnippet-snippets
      ];
    };
}
