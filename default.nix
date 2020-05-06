with import <nixpkgs> {};

let
  noise = fetchFromGitHub {
    owner = "jangko";
    repo = "nim-noise";
    rev = "master";
    sha256 = "1bg8vjirf87526pk8ii8n3kp8f2fffhlcs1mdh1ahljcw8zbnq1k";
  };

  nimbox = fetchFromGitHub {
    owner = "dom96";
    repo = "nimbox";
    rev = "master";
    sha256 = "15x1sdfxa1xcqnr68705jfnlv83lm0xnp2z9iz3pgc4bz5vwn4x1";
  };

  lscolors = fetchFromGitHub {
    owner = "joachimschmidt557";
    repo = "nim-lscolors";
    rev = "v0.3.3";
    sha256 = "0526hqh46lcfsvymb67ldsc8xbfn24vicn3b8wrqnh6mag8wynf4";
  };

in stdenv.mkDerivation rec {
  pname = "nimmm";
  version = "0.1.2";

  src = ./.;
  # src = fetchFromGitHub {
  #   owner = "joachimschmidt557";
  #   repo = pname;
  #   rev = "v${version}";
  #   sha256 = "1zpq181iz6g7yfi298gjwv33b89l4fpnkjprimykah7py5cpw67w";
  # };

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
}
