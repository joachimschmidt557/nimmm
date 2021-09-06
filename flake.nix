{
  description = "Terminal file manager written in nim";

  inputs.noise = {
    url = "github:jangko/nim-noise/v0.1.14";
    flake = false;
  };

  inputs.nimbox = {
    url = "github:dom96/nimbox";
    flake = false;
  };

  inputs.lscolors = {
    url = "github:joachimschmidt557/nim-lscolors/v0.3.3";
    flake = false;
  };

  outputs = { self, nixpkgs, noise, nimbox, lscolors }: {

    packages.x86_64-linux.nimmm =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        pname = "nimmm";
        version = "master";

        src = self;

        nativeBuildInputs = [ nim ];
        buildInputs = [ termbox pcre ];

        NIX_LDFLAGS = "-lpcre";

        buildPhase = ''
          export HOME=$TMPDIR;
          nim -p:${noise} -p:${nimbox} -p:${lscolors}/src c -d:release src/nimmm.nim
        '';

        installPhase = ''
          install -Dt $out/bin src/nimmm
        '';
      };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.nimmm;

    hydraJobs.nimmm.x86_64-linux = self.packages.x86_64-linux.nimmm;

  };
}
