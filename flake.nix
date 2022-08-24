{
  description = "Terminal file manager written in nim";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nimbox = {
    url = "github:dom96/nimbox";
    flake = false;
  };

  inputs.lscolors = {
    url = "github:joachimschmidt557/nim-lscolors/v0.3.3";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, nimbox, lscolors }:
    (flake-utils.lib.eachDefaultSystem
      (system:

        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {

          packages.nimmm =
            pkgs.stdenv.mkDerivation {
              pname = "nimmm";
              version = "master";

              src = self;

              nativeBuildInputs = with pkgs; [ nim ];
              buildInputs = with pkgs; [ termbox pcre ];

              NIX_LDFLAGS = "-lpcre";

              buildPhase = ''
                export HOME=$TMPDIR;
                nim --threads:on -p:${nimbox} -p:${lscolors}/src c -d:release src/nimmm.nim
              '';

              installPhase = ''
                install -Dt $out/bin src/nimmm
              '';
            };

          defaultPackage = packages.nimmm;

        })) // {
      hydraJobs.nimmm.x86_64-linux = self.packages.x86_64-linux.nimmm;
    };
}
