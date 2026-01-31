{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.bazelisk
    pkgs.git
  ];

  # https://devenv.sh/basics/
  enterShell = ''
    alias bazel='bazelisk'
  '';
}
