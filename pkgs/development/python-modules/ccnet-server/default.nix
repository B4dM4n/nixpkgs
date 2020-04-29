{ stdenv
, lib
, buildPythonPackage
, autoreconfHook
, fetchFromGitHub
, glib
, libevent
, libsearpc
, libuuid
, libzdb
, openssl
, pkg-config
, vala
, which
, sqlite
, postgresqlSupport ? true
, postgresql
, mysqlSupport ? true
, mysql
}:

with lib;
buildPythonPackage rec {
  version = "7.1.5";
  pname = "ccnet-server";

  src = fetchFromGitHub {
    owner = "haiwen";
    repo = pname;
    rev = "v${version}-server";
    sha256 = "1fzgd0rb4r4sb4vv41h79d8sf4jmax1gg5644dp8vn0q8n3fbkv7";
  };

  format = "other";
  outputs = [ "out" "lib" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libsearpc
    pkg-config
    vala
    which
  ];
  buildInputs = [
    glib
    libevent
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

  meta = {
    homepage = "https://github.com/haiwen/ccnet-server";
    description = "Internal communication framework and user/group management for Seafile server";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
