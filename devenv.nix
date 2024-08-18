{ pkgs, ... }:
{
  packages = [
    pkgs.go-task
    pkgs.kubernetes-helm
    pkgs.envsubst
    pkgs.age
    pkgs.pre-commit
  ];
}
