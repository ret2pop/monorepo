{
  description = "Build my static site with my installer";

  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixmacs.url = "path:./nix";

    publish-org-roam-ui = {
      url = "git://nullring.xyz/publish-org-roam-ui.git";
    };

    garamond = {
      url = "github:fontalternative/cormorant-garamond";
      flake = false;
    };
  };

  outputs = { nixpkgs, git-hooks, nixmacs, self, publish-org-roam-ui, garamond, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      emacsPackages = import  "${nixmacs}/modules/home/emacs-packages.nix";
      ci-emacs = pkgs.emacs-nox.pkgs.withPackages emacsPackages;
      specialArgs = { monorepoSelf = self; };

      installer = nixmacs.nixosConfigurations.installer.extendModules {
        inherit specialArgs;
      };

      spontaneity = nixmacs.nixosConfigurations.spontaneity.extendModules {
        inherit specialArgs;
      };

      affinity = nixmacs.nixosConfigurations.affinity.extendModules {
        inherit specialArgs;
      };

      installer-iso = installer.config.system.build.isoImage;

      spontaneityHost = spontaneity.config.monorepo.vars.orgHost;

      secretsPath = affinity.config.home-manager.sops.defaultSymlinkPath;

      ntfyFile = affinity.config.monorepo.vars.ntfySecret;

      topology = nixmacs.topology.x86_64-linux.config.output;

      pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          deadnix.enable = true;
          website-build-check = {
            enable = true;
            name = "website-build";
            description = "Ensure website can build, and tests links";
            stages = [ "pre-merge-commit" ];
            entry = "${pkgs.writeShellScript "website-check" ''
set -e 
set -o pipefail 
trap "echo -e '\nHook interrupted by user. Aborting merge!'; exit 1" INT TERM

BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  exit 0
fi
RESULT_PATH=$(nix build .#website --no-link --print-out-paths)
if [ -d "$RESULT_PATH" ]; then
  echo "Running lychee link check..."
  ${pkgs.lychee}/bin/lychee --root-dir "$RESULT_PATH" \
    --offline \
    --verbose \
    --no-progress \
    "$RESULT_PATH/**/*.html"
else
  echo "Website build failed, skipping lychee."
  exit 1
fi
''}";
            pass_filenames = false;
            always_run = true;
          };

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

          deploy-spontaneity = {
            enable = true;
            name = "Deploy to Spontaneity VPS";
            description = "Automatically deploys the NixOS configuration to the VPS on push to main";
            stages = [ "pre-push" ]; 
            pass_filenames = false;
            always_run = true;
            entry = "${pkgs.writeShellScript "deploy-spontaneity-hook" ''
BRANCH=$(git branch --show-current)
              
if [ "$BRANCH" != "main" ]; then
  exit 0
fi
echo "Pushing to main detected. Deploying to ${spontaneityHost}..."
export NIX_SSHOPTS="-t"

if [ $? -eq 0 ]; then
  echo "Deployment successful!"
else
  echo "Deployment failed. Aborting."
  exit 1
fi
            ''}";
          };
        };
      };

      website = pkgs.stdenv.mkDerivation {
        name = "org-publish-website";
        src = pkgs.lib.cleanSource ./.;
        nativeBuildInputs = [
          installer-iso
        ];
        buildInputs = [
          ci-emacs
          pkgs.git
          pkgs.aspell 
          pkgs.aspellDicts.en
          pkgs.sqlite
          pkgs.ghostscript
          pkgs.imagemagick
          pkgs.jq
          pkgs.lora
          pkgs.inconsolata
          pkgs.stix-two
          pkgs.pandoc
          pkgs.rsass
          pkgs.minify
          pkgs.woff2

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
mkdir -p mindmap/img
rsass style.scss | minify --type=css > style.css
minify --type=css -o syntax.css syntax.css

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
  --eval '(setq system-fullname "Preston Pan")' \
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
  --eval '(setq load-prefer-newer t)' \
  --eval '(setq gc-cons-threshold 100000000)' \
  --eval '(setq vc-handled-backends nil)' \
  --eval '(setq make-backup-files nil auto-save-default nil create-lockfiles nil)' \
  -l ${nixmacs}/init.el \
  --eval '(setq custom-safe-themes t)' \
  --eval '(setq org-roam-directory (expand-file-name "mindmap" (expand-file-name "~/monorepo")))' \
  --eval '(setq org-id-track-globally t)' \
  --eval '(org-roam-db-sync)' \
  --eval '(setq term-file-prefix nil)' \
  --eval '(force-mode-line-update)' \
  --eval '(setq org-html-link-use-abs-url nil)' \
  --eval '(setq default-directory (expand-file-name "~/monorepo"))' \
  --eval '(setq org-html-link-use-abs-url nil)' \
  --eval '(setq org-html-link-org-files-as-html t)' \
  --eval '(require (quote htmlize))' \
  --eval '(require (quote nix-mode))' \
  --eval '(setq org-html-htmlize-output-type (quote css))' \
  --eval '(org-publish-all t)' \
  --eval '(org-publish-all nil)' || (echo "FAIL:" && cat /build/*.log && exit 1)

echo "Setting up Graph View..."
${publish-org-roam-ui.packages.${system}.default}/bin/build-org-roam-graph \
  $HOME/.emacs.d/org-roam.db \
  $HOME/monorepo/mindmap \
  $HOME/website_html/graph_view
          '';

        installPhase = ''
mkdir -p $out/fonts

cp -L ${pkgs.lora}/share/fonts/truetype/*.ttf $out/fonts/
cp -L ${pkgs.inconsolata}/share/fonts/truetype/inconsolata/*.ttf $out/fonts

cp -L ${pkgs.stix-two}/share/fonts/truetype/STIXTwoMath-Regular.ttf $out/fonts/

cp ${garamond}/ttf/CormorantGaramond-Medium.ttf $out/fonts/
cp ${garamond}/ttf/CormorantGaramond-MediumItalic.ttf $out/fonts/
cp ${garamond}/ttf/CormorantGaramond-Bold.ttf $out/fonts/

for font in $out/fonts/*.ttf; do
   woff2_compress "$font"
   rm "$font"
done

cp -r $HOME/website_html/. $out/
cp ${topology}/main.svg $out/img/topology.svg
cp ${installer-iso}/iso/*.iso $out/installer.iso
cd $out
sha256sum installer.iso > installer.iso.sha256
          '';
      };
    in
      {
        nixosConfigurations = {
          inherit installer;
          inherit spontaneity;
        };

        checks."${system}" = {
          build-website = website;
        };

        packages."${system}" = {
          website = website;
          installer = installer-iso;
          spontaneity = self.nixosConfigurations.spontaneity.config.system.build.toplevel;
        };

        devShells."${system}".default = with pkgs; mkShell {
          shellHook = ''
${pre-commit-check.shellHook}
git config branch.main.mergeoptions "--no-ff"
alias gprune='git branch --merged | grep -v -E "^\*|main|master|dev" | xargs -r git branch -d'
alias serve='cd result; python3 -m http.server 10005'
alias build='nix build .#website && curl -u "ret2pop:$(grep ADMIN_PASSWORD "${secretsPath}/${ntfyFile}" | cut -d "\"" -f 2)" -d "Website build done!" https://ntfy.ret2pop.net'
'';
          buildInputs = [
            deadnix
            lychee
            python3
            miniserve
            rsass
            imagemagickBig
          ];
        };
      };
}
