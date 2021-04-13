{ pkgs ? import <nixpkgs> {} }:

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

in pkgs.stdenv.mkDerivation rec {
  pname = "nimmm";
  version = "master";

  src = ./.;
  # src = fetchFromGitHub {
  #   owner = "joachimschmidt557";
  #   repo = pname;
  #   rev = "v${version}";
  #   sha256 = "1zpq181iz6g7yfi298gjwv33b89l4fpnkjprimykah7py5cpw67w";
  # };

  nativeBuildInputs = with pkgs; [ nim ];
  buildInputs = with pkgs; [ termbox pcre ];

  NIX_LDFLAGS = "-lpcre";

  buildPhase = ''
    export HOME=$TMPDIR;
    nim -p:${noise} -p:${nimbox} -p:${lscolors}/src c -d:release src/nimmm.nim
  '';

  installPhase = ''
    install -Dt $out/bin src/nimmm
  '';
}
