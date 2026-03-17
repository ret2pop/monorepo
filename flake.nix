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
      ci-emacs = pkgs.emacs-gtk.pkgs.withPackages emacsPackages;
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

      userName = spontaneity.config.monorepo.vars.userName;

      internetName = spontaneity.config.monorepo.vars.internetName;

      secretsPath = affinity.config.home-manager.users."${userName}".sops.defaultSymlinkPath;

      ntfyFile = affinity.config.monorepo.vars.ntfySecret;

      ntfyHost = "https://${spontaneity.config.monorepo.vars.ntfyUrl}";

      topology = nixmacs.topology.x86_64-linux.config.output;

      mkNotification = msg: ''curl -H "Priority: 4" -u "${internetName}:$(grep ADMIN_PASSWORD "${secretsPath}/${ntfyFile}" | cut -d "\"" -f 2)" -d "${msg}" ${ntfyHost}/ci-build'';

      pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          deadnix.enable = true;
          spontaneity-smoke-test = {
            enable = true;
            name = "Spontaneity smoke test";
            description = "tests if nginx is active/if the config works.";
            stages = [ "pre-merge-commit" ];
            entry = "${pkgs.writeShellScript "website-check" ''
set -e
set -o pipefail
trap "echo -e '\nHook interrupted by user. Aborting merge!'; exit 1" INT TERM

BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  exit 0
fi

set +e
nix build .#checks.${system}.spontaneity-website-test --no-link
BUILD_STATUS=$?
set -e

if [ $BUILD_STATUS -neq 0 ]; then
  echo "Failed to build the website with spontaneity!"
  exit $BUILD_STATUS
fi
''}";
            pass_filenames = false; 
          };

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

set +e
RESULT_PATH=$(nix build .#website --no-link --print-out-paths)
BUILD_STATUS=$?
set -e

if [ $BUILD_STATUS -eq 0 ] && [ -d "$RESULT_PATH" ]; then
    echo "Running lychee link check..."
    set +e
    ${pkgs.lychee}/bin/lychee --root-dir "$RESULT_PATH" \
      --offline \
      --verbose \
      --no-progress \
      "$RESULT_PATH/**/*.html"
      LYCHEE_STATUS=$?
    set -e

    if [ $LYCHEE_STATUS -ne 0 ]; then
      echo "Lychee found broken links!"
      ${mkNotification "CI checks failed: Broken links!"}
      exit 1
    fi

    INJECT_HASH="$(python3 tests/test-csp-hash.py "$RESULT_PATH/blog/index.html")"
    HEADER_HASH="$(cat "$RESULT_PATH/csp_header.conf" | grep -oP "sha256-\K[^']+")"

    if [ "$INJECT_HASH" != "$HEADER_HASH" ]; then
      echo "Security headers test failed!"
      ${mkNotification "CI checks failed: CSP hash mismatch!"}
      exit 1
    fi

    ${mkNotification "CI checks done!"}
else
  echo "Website build failed, skipping lychee and CSP tests."
  ${mkNotification "CI checks failed!"}
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
          pkgs.openssl
          pkgs.xvfb-run
          pkgs.python3

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

cat <<EOF > $TMPDIR/policy.xml
<policymap>
  <policy domain="coder" rights="read|write" pattern="{PDF,PS,EPS,GS}" />
</policymap>
EOF
export MAGICK_CONFIGURE_PATH=$TMPDIR
export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
export FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/
export XDG_CACHE_HOME=$TMPDIR/.cache
printf "hello?\n"

export NIXMACS_DIR="${nixmacs}"

xvfb-run -a emacs -q -l ${self}/tests/ci-runner.el || {
  echo "FAIL: Emacs build crashed."
  cat /build/*.log
  exit 1
}

printf "after emacs\n"
CSS_HASH="$(python3 $HOME/monorepo/tests/test-csp-hash.py $HOME/website_html/index.html)"
cat <<EOF > $HOME/website_html/csp_header.conf
add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'sha256-$CSS_HASH'; font-src 'self';";
EOF

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
          spontaneity-website-test = nixmacs.inputs.nixpkgs.legacyPackages."${system}".testers.runNixOSTest {
            name = "spontaneity-website-test";
            
            node.specialArgs = { 
              monorepoSelf = self; 
              isIntegrationTest = true;
            } // nixmacs.inputs;

            nodes."spontaneity" = { lib, ... }: {
              imports = nixmacs.lib.mkHostModules "spontaneity" ++ [
                "${nixmacs.inputs.nixpkgs}/nixos/modules/misc/nixpkgs/read-only.nix"
                {
                  nixpkgs.pkgs = lib.mkVMOverride self.nixosConfigurations.spontaneity.pkgs;
                  nixpkgs.config = lib.mkForce {};
                  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
                  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
                  nixpkgs.overlays = lib.mkForce [];
                }
              ];
              disabledModules = [
                "${self}/nix/modules/nixpkgs-options.nix"
                "${self}/nix/systems/spontaneity/hardware-configuration.nix"
              ];
            };

            testScript = ''
spontaneity.start()
spontaneity.succeed('printf "smoke"')
spontaneity.wait_for_unit("default.target")
spontaneity.succeed("systemctl is-active nginx")
spontaneity.succeed('printf "smoke again"')
          '';
          };
        };

        packages."${system}" = {
          default = website;
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
alias build='nix build .#website -L && ${mkNotification "CI build done!"} '
alias check='nix flake check; ${mkNotification "flake checks done!"} '
'';
          buildInputs = [
            deadnix
            lychee
            python3
            miniserve
            rsass
            imagemagickBig
            google-lighthouse
            openssl
            git
          ];
        };
      };
}
