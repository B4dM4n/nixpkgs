{ stdenv
, lib
, autoreconfHook
, fetchFromGitHub
, pkgconfig
, python
, vala
, which
, glib
, libevent
, libsearpc
, libuuid
, libzdb
, openssl
, sqlite
, postgresqlSupport ? true
, postgresql
, mysqlSupport ? true
, mysql
}:

with lib;
python.pkgs.toPythonModule
  (stdenv.mkDerivation rec {
    version = "7.1.3";
    pname = "ccnet-server";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = pname;
      rev = "v${version}-server";
      sha256 = "0hf9mmf019984ybc20zxaqyhcfhhr3k0bjr45pq9d79w16ndnim8";
    };

    outputs = [ "out" "lib" "dev" ];

    nativeBuildInputs = [
      autoreconfHook
      pkgconfig
      python
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
      maintainers = [ b4dm4n ];
    };
  })
