{
  description = "Python dev environment with uv and direnv";

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
            uv
            go-task
            kubernetes-helm
            envsubst
            age
            pre-commit
            mariadb
            popeye
            ansible
          ];

          # Environment variables and commands to run when entering the shell.
          # This is where we integrate UV and the virtual environment.
          shellHook = ''
            # Create a virtual environment if it doesn't exist.
            # We place it in .venv in the project root.
            if [ ! -d ".venv" ]; then
              echo -e "\033[1;34mCreating virtual environment with uv...\033[0m"
              ${pkgs.uv}/bin/uv venv .venv
            fi

            # Activate the virtual environment
            source ./.venv/bin/activate

            # Install/sync dependencies from pyproject.toml or requirements.txt
            # You can choose one of these. pyproject.toml (Poetry/Rye/PDM) is generally preferred.
            if [ -f "pyproject.toml" ]; then
              echo -e "\033[1;34mSyncing dependencies with uv...\033[0m"
              # uv sync --extra=dev  # if you have [tool.uv.extras.dev] defined
              uv sync
            elif [ -f "requirements.txt" ]; then
              echo -e "\033[1;34mInstalling dependencies from requirements.txt with uv...\033[0m"
              uv pip install -r requirements.txt
            else
              echo -e "\033[1;34mNo pyproject.toml or requirements.txt found. Manage dependencies manually with uv pip install.\033[0m"
            fi

            echo -e "\033[1;34m$(python --version) | $(uv --version)\033[0m"
          '';
        };
      });
}
