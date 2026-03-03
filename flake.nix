{
  description = "Build my static site with my installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprnixmacs.url = "git+file:./nix";
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
        buildInputs = [ ci-emacs ];
        buildPhase = ''
mkdir -p public
emacs -Q --batch \
  --eval '(setq system-email "ci@dummy.local")' \
  --eval '(setq system-username "ci-runner")' \
  --eval '(setq system-fullname "CI Pipeline")' \
  --eval '(setq system-gpgkey "00000000")' \
  -l ./nix/init.el \
  --eval '(org-publish-all t)'
          '';

        installPhase = ''
mkdir -p $out
cp -r public/* $out/
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
          ];
        };
      };
}
