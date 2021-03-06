{ stdenv, fetchFromGitHub, cmake, asciidoc, enableDrafts ? false }:

stdenv.mkDerivation rec {
  name = "zeromq-${version}";
  version = "4.3.2";

  src = fetchFromGitHub {
    owner = "zeromq";
    repo = "libzmq";
    rev = "v${version}";
    sha256 = "1q37z05i76ili31j6jlw8988iy6vxadlmd306f99phxfdpqa6bn9";
  };

  nativeBuildInputs = [ cmake asciidoc ];

  enableParallelBuilding = true;

  doCheck = false; # fails all the tests (ctest)

  cmakeFlags = if enableDrafts then [ "-DENABLE_DRAFTS=ON" ] else null;

  meta = with stdenv.lib; {
    branch = "4";
    homepage = http://www.zeromq.org;
    description = "The Intelligent Transport Layer";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ fpletz ];
  };
}
