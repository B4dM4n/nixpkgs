{ stdenv, lib, fetchFromBitbucket, makeWrapper, python }:

stdenv.mkDerivation rec {
  pname = "playscii";
  version = "0.9.14";

  src = fetchFromBitbucket {
    owner = "JPLeBreton";
    repo = pname;
    name = pname;
    rev = "37a8634c4d33ab017a84d6333173442ae9386bcd";
    sha256 = "0s3nqn8317y5gwjmc3b67jllahlf587kh370hgch98qxdqwz9r4b";
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
