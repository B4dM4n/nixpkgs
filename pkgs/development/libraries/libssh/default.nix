{ lib
, stdenv
, fetchurl
, pkg-config
, cmake
, zlib
, openssl
, withSodium ? true
, libsodium
}:

assert withSodium -> libsodium != null;

stdenv.mkDerivation rec {
  pname = "libssh";
  version = "0.8.9";

  src = fetchurl {
    url = "https://www.libssh.org/files/0.8/${pname}-${version}.tar.xz";
    sha256 = "09b8w9m5qiap8wbvz4613nglsynpk8hn0q9b929ny2y4l2fy2nc5";
  };

  postPatch = lib.optionalString withSodium ''
    # Fix headers to use libsodium instead of NaCl
    sed -i 's,nacl/,sodium/,g' ./include/libssh/curve25519.h src/curve25519.c
  '';

  cmakeFlags = lib.optionals withSodium [
    "-DWITH_NACL=ON"
    "-DNACL_LIBRARY=${lib.getLib libsodium}/lib/libsodium.so"
    "-DNACL_INCLUDE_DIR=${lib.getDev libsodium}/include"
    "-DNACL_LIBRARIES=ignored" # only checked for existence
    "-DNACL_INCLUDE_DIRS=ignored" # only checked for existence
  ];

  # single output, otherwise cmake and .pc files point to the wrong directory
  # outputs = [ "out" "dev" ];

  buildInputs = [ zlib openssl ]
    ++ lib.optionals withSodium [ libsodium ];

  nativeBuildInputs = [ cmake pkg-config ];

  meta = with lib; {
    description = "SSH client library";
    homepage = "https://libssh.org";
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ sander ];
    platforms = platforms.all;
  };
}
