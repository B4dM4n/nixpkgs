{ stdenv, lib, fetchFromBitbucket, makeWrapper, python }:

stdenv.mkDerivation rec {
  pname = "playscii";
  version = "9.16.2";

  src = fetchFromBitbucket {
    owner = "JPLeBreton";
    repo = pname;
    name = pname;
    rev = "8d6597515d535e559cf65d5d02f0770ec9b2b9d0";
    sha256 = "0vlj8fgblfnzixyrnj7jl7gknhrpcrl2li185778wbcx0k73cnyd";
  };

  preUnpack = ''
    mkdir -p $out/opt
    cd $out/opt
  '';

  nativeBuildInputs = [ makeWrapper ];
  buildInputs =
    [ (python.withPackages (ps: with ps; [ appdirs gprof2dot numpy pillow pyopengl pysdl2 ])) ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper $out/opt/playscii/playscii.py $out/bin/playscii \
      --run "cd $out/opt/playscii"
    patchShebangs $out/opt/playscii
  '';

  meta = with lib; {
    description = "An open source ASCII art, animation, and game creation program";
    homepage = "http://vectorpoem.com/playscii/";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
