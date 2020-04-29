{ stdenv
, lib
, callPackage
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, python
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
let
  ccnet-server' = ccnet-server.override { inherit python; };
  libsearpc' = libsearpc.override { inherit python; };
in
python.pkgs.toPythonModule
  (stdenv.mkDerivation rec {
    version = "7.1.3";
    pname = "seafile-server";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = pname;
      rev = "v${version}-server";
      sha256 = "0fn5adz55xlwszlda8dgx6ahvnq6p9gkw80nyj3d3zw8vmgj154x";
    };

    outputs = [ "out" "dev" ];

    nativeBuildInputs = [
      autoreconfHook
      pkgconfig
      python
      vala
      which
    ];
    buildInputs = [
      ccnet-server'
      fuse
      glib
      libarchive
      libevent
      libevhtp
      libsearpc'
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
      maintainers = [ b4dm4n ];
    };
  })
