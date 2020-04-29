{stdenv, fetchFromGitHub, cmake, libevent}:

stdenv.mkDerivation rec {
  pname = "libevhtp";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "criticalstack";
    repo = pname;
    rev = version;
    sha256 = "1k11r6gvndd1nzk6gs896hpfl5cnqir7jrl4jn7p5hsqpllzjjzs";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libevent ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/ellzey/libevhtp";
    description = "Libevhtp was created as a replacement API for Libevent's current HTTP API2";
    license = licenses.lgpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
