{ stdenv
, lib
, buildPythonPackage
, callPackage
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, vala
, which
, ccnet-server
, fuse
, glib
, libarchive
, libevent
, libevhtp
, libsearpc
, libuuid
, openssl
, sqlite
, postgresqlSupport ? true
, postgresql
, mysqlSupport ? true
, mysql
}:

with lib;
buildPythonPackage rec {
  version = "8.0.2";
  pname = "seafile-server";

  src = fetchFromGitHub {
    owner = "haiwen";
    repo = pname;
    rev = "v${version}-server";
    sha256 = "sha256-bKYmuKxLG4S815rp9VxlAu0H2OF8sy/r6c297p9//yc=";
  };

  format = "other";
  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libsearpc
    pkgconfig
    vala
    which
  ];
  buildInputs = [
    ccnet-server
    fuse
    glib
    libarchive
    libevent
    libevhtp
    libsearpc
    libuuid
    openssl
    sqlite
  ]
  ++ optional postgresqlSupport postgresql
  ++ optional mysqlSupport mysql;

  configureFlags = optional (! postgresqlSupport) "--without-postgresql"
    ++ optional (! mysqlSupport) "--without-mysql";

  enableParallelBuilding = true;

  passthru.scripts = callPackage ./scripts.nix { };

  meta = with stdenv.lib; {
    homepage = "https://github.com/haiwen/seafile-server";
    description = "Seafile Server Core";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
