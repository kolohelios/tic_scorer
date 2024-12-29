{ pkgs, ... }:

{
  packages = with pkgs; [
    ripgrep
    just
  ];

  languages.rust.enable = true;
}

