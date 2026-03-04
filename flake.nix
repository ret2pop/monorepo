{
  description = "Build my static site with my installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprnixmacs.url = "git://nullring.xyz/hyprnixmacs.git";
  };

  outputs = { nixpkgs, git-hooks, hyprnixmacs, self, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          deadnix.enable = true;
          prevent-direct-main-commits = {
            enable = true;
            name = "Prevent direct commits to main";
            description = "Blocks commits to main unless they are merge commits";
            pass_filenames = false;
            entry = "${pkgs.writeShellScript "block-main-commits" ''
BRANCH=$(git branch --show-current)
GIT_DIR=$(git rev-parse --git-dir)
if [ "$BRANCH" = "main" ] && [ ! -f "$GIT_DIR/MERGE_HEAD" ]; then
  echo "Direct commits to 'main' are blocked."
  echo "Please commit to a feature branch and merge it into main."
  exit 1
fi
                ''}";
          };
        };
      };

      emacsPackages = import  "${hyprnixmacs}/modules/home/emacs-packages.nix";
      ci-emacs = pkgs.emacs-nox.pkgs.withPackages emacsPackages;
      website = pkgs.stdenv.mkDerivation {
        name = "org-publish-website";
        src = pkgs.lib.cleanSource ./.;
        buildInputs = [
          ci-emacs
          pkgs.git
          pkgs.aspell 
          pkgs.aspellDicts.en
          pkgs.sqlite
          pkgs.ghostscript
          pkgs.imagemagick
          (pkgs.texlive.combine {
            inherit (pkgs.texlive)
              scheme-full
              circuitikz
              standalone
              dvipng
              capt-of
              dvisvgm;
          })
        ];
        buildPhase = ''
export HOME=$TMPDIR/fake-home
mkdir -p $HOME/.emacs.d
mkdir -p public
mkdir -p .cache/texmf

export TEXMFVAR=$HOME/.cache/texmf
mkdir -p $HOME/monorepo
cp -a . $HOME/monorepo/
cd $HOME/monorepo

cat <<EOF > $TMPDIR/policy.xml
<policymap>
  <policy domain="coder" rights="read|write" pattern="{PDF,PS,EPS,GS}" />
</policymap>
EOF
export MAGICK_CONFIGURE_PATH=$TMPDIR
export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
export FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/
export XDG_CACHE_HOME=$TMPDIR/.cache

emacs -q --batch \
  --eval '(setq noninteractive t)' \
  --eval '(setq system-email "lol@troll.com")' \
  --eval '(setq system-username "ci-runner")' \
  --eval '(setq system-fullname "CI")' \
  --eval '(setq system-gpgkey "00000000")' \
  --eval '(defun package-vc-install (&rest args) (message "blocked package-vc-install for %s" args))' \
  --eval '(defun package-vc--unpack (&rest args) nil)' \
  --eval '(setq package-archives nil)' \
  --eval '(setq use-package-always-ensure nil)' \
  --eval '(setq package-vc-selected-packages nil)' \
  --eval '(defalias (quote scroll-bar-mode) (quote ignore))' \
  --eval '(defalias (quote tool-bar-mode) (quote ignore))' \
  --eval '(defalias (quote menu-bar-mode) (quote ignore))' \
  --eval '(provide (quote lean4-mode))' \
  --eval '(provide (quote irony-mode))' \
  --eval '(provide (quote irony))' \
  --eval '(defalias (quote irony-cdb-autosetup-compile-options) (quote ignore))' \
  --eval "(setq org-latex-pdf-process (quote (\"xelatex -shell-escape -interaction nonstopmode %f\")))" \
  --eval '(setq org-startup-with-latex-preview nil)' \
  --eval '(setq org-startup-indented nil)' \
  --eval '(setq org-export-with-latex t)' \
  --eval '(setq org-confirm-babel-evaluate nil)' \
  -l ${hyprnixmacs}/init.el \
  --eval "(org-babel-do-load-languages 'org-babel-load-languages '((latex . t)))" \
  --eval '(setq org-roam-directory (expand-file-name "mindmap" (expand-file-name "~/monorepo")))' \
  --eval '(setq org-id-track-globally t)' \
  --eval '(org-roam-db-sync)' \
  --eval '(org-publish-all t)' || (echo "FAIL:" && cat /build/*.log && exit 1)
          '';

        installPhase = ''
mkdir -p $out
cp -r $HOME/website_html/. $out/
          '';
      };
    in
      {
        nixosConfigurations.installer = hyprnixmacs.nixosConfigurations.installer.extendModules {
          specialArgs = { monorepoSelf = self; };
        };

        checks."${system}" = {
          build-website = website;
        };

        packages."${system}" = {
          default = website;
          installer = self.nixosConfigurations.installer.config.system.build.isoImage;
        };
        devShells."${system}".default = with pkgs; mkShell {
          inherit (pre-commit-check) shellHook;
          buildInputs = [
            deadnix
            lychee
          ];
        };
      };
}
