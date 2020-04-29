{ stdenv
, callPackage
, runCommand
, fetchFromGitHub
, python3
, gettext
, ccnet-server
, libsearpc
, nodePackages
, nodejs
, seafile-server
, seahub
}:
let
  python = python3;

  ccnet-server' = ccnet-server.override { inherit python; };
  libsearpc' = libsearpc.override { inherit python; };
  seafile-server' = seafile-server.override { inherit python; };

  source = stdenv.mkDerivation rec {
    pname = "seahub-source";
    version = "7.1.3";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = pname;
      rev = "v${version}-server";
      sha256 = "0kqvsmbg5jqjaas4gvza9byg0nspd141syyb0zfv6b9s1mp2pd5n";
    };

    postPatch = ''
      sed -i -e '/process\.env\.NODE_PATH =/,/;/d' frontend/config/env.js
    '';

    outputs = [ "out" "thirdpart" "frontend" ];

    dontBuild = true;

    installPhase = ''
      mv thirdpart $thirdpart
      mv frontend $frontend
      mv $PWD $out
    '';
  };

  python' = callPackage ./python-packages.nix { inherit python; };
  thirdpart = python'.pkgs.toPythonModule
    (runCommand "seahub-thirdpart-${source.version}" { } ''
      mkdir -p $(dirname $out/${python'.sitePackages})
      ln -s ${source.thirdpart} $out/${python'.sitePackages}
    '');
  frontend-build = callPackage ./frontend-build.nix {
    inherit source;
    sha256 = "1c7kq28j1z82vlx14dbd09q2130cc10r74sjz448f31mxv5m8l3j";
  };
in
python.pkgs.toPythonModule
  (stdenv.mkDerivation rec {
    pname = "seahub";
    inherit (source) version;

    src = source;

    nativeBuildInputs = [ python' gettext ];
    propagatedBuildInputs = with python'.pkgs; [
      ccnet-server'
      django
      django-formtools
      django-picklefield
      django-post_office
      django-simple-captcha
      django-statici18n
      django-webpack_loader
      djangorestframework
      future
      gunicorn
      libsearpc'
      openpyxl
      pillow
      pycryptodome
      pyjwt
      pymysql
      python-dateutil
      qrcode
      requests
      seafile-server'
      thirdpart
    ];

    buildPhase = ''
      mkdir frontend
      ln -sn ${frontend-build} frontend/build
      CCNET_CONF_DIR=/ CCNET_CONF_PATH=/ SEAFILE_CONF_DIR=/ SEAFILE_CENTRAL_CONF_DIR=/ SEAFILE_RPC_PIPE_PATH=/ make dist
      rm -R bin
    '';

    installPhase = ''
      cp -R . $out
      mkdir -p $out/${python'.sitePackages}
      ln -s $out/seahub $out/${python'.sitePackages}/seahub
    '';

    passthru.python = python'.withPackages (p: [ seahub ]);

    meta = with stdenv.lib; {
      homepage = "https://github.com/haiwen/seahub";
      description = "Seahub is the web frontend for Seafile";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [ b4dm4n ];
    };
  })
