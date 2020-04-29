{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, python
, vala
, which
, libevent
, libsearpc
, libuuid
, openssl
, sqlite
}:
let
  libsearpc' = libsearpc.override { inherit python; };
in
python.pkgs.toPythonModule
  (stdenv.mkDerivation rec {
    version = "6.1.8";
    pname = "ccnet";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = pname;
      rev = "v${version}";
      sha256 = "1zhin6iccy251ciqsk82ly25hg10iahc8jf6z50nkfsxa016ccqn";
    };

    outputs = [ "out" "lib" "dev" ];

    nativeBuildInputs = [ pkgconfig which autoreconfHook vala python ];
    buildInputs = [ libsearpc' libuuid libevent sqlite openssl ];

    enableParallelBuilding = true;

    meta = with stdenv.lib; {
      homepage = "https://github.com/haiwen/ccnet";
      description = "A framework for writing networked applications in C";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  })
