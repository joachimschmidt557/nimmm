{ ... }:
let
  nixpkgs = (import <nixpkgs>) {};
in {
  nimmm = (import ./default.nix) {
    pkgs = nixpkgs;
  };
}
