{
  description = "Dev environment with direnv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go-task
            kubernetes-helm
            envsubst
            age
            pre-commit
            mariadb
            popeye
            ansible
            jq
          ];

          # Environment variables and commands to run when entering the shell.
          shellHook = ''
          '';
        };
      });
}
