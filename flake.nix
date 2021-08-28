{
  description = "Terminal file manager written in nim";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.nimmm =
      with import nixpkgs { system = "x86_64-linux"; };
      let
        noise = pkgs.fetchFromGitHub {
          owner = "jangko";
          repo = "nim-noise";
          rev = "v0.1.14";
          sha256 = "0wndiphznfyb1pac6zysi3bqljwlfwj6ziarcwnpf00sw2zni449";
        };

        nimbox = pkgs.fetchFromGitHub {
          owner = "dom96";
          repo = "nimbox";
          rev = "6a56e76c01481176f16ae29b7d7c526bd83f229b";
          sha256 = "15x1sdfxa1xcqnr68705jfnlv83lm0xnp2z9iz3pgc4bz5vwn4x1";
        };

        lscolors = pkgs.fetchFromGitHub {
          owner = "joachimschmidt557";
          repo = "nim-lscolors";
          rev = "v0.3.3";
          sha256 = "0526hqh46lcfsvymb67ldsc8xbfn24vicn3b8wrqnh6mag8wynf4";
        };

      in
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
