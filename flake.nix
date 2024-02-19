{
  description = "Terminal file manager written in nim";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    (flake-utils.lib.eachDefaultSystem
      (system:

        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {

          packages.nimmm =
            pkgs.buildNimPackage {
              pname = "nimmm";
              version = "master";

              src = self;

              lockFile = ./lock.json;

              buildInputs = with pkgs; [ termbox pcre ];
            };

          defaultPackage = packages.nimmm;

        }));
}
