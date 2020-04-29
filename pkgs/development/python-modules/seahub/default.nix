{ stdenv
, buildPythonPackage
, runCommand
, fetchFromGitHub
, python
, gettext
, ccnet-server
, libsearpc
, nodePackages
, nodejs
, seafile-server
}:
let
  source = stdenv.mkDerivation rec {
    pname = "seahub-source";
    version = "8.0.2";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = "seahub";
      rev = "v${version}-server";
      sha256 = "sha256-OMK0z5l6IgKbPkpi54Eu1XOH4sfGNt+pmLeZiU23xyQ=";
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

  thirdpart = python.pkgs.toPythonModule
    (runCommand "seahub-thirdpart-${source.version}" { } ''
      mkdir -p $(dirname $out/${python.sitePackages})
      ln -s ${source.thirdpart} $out/${python.sitePackages}
    '');
  frontend-build = import ./frontend-build.nix {
    inherit stdenv nodejs source;
    sha256 = "sha256-bVqBIhVAX0fCHbeZWEvWlmMBc8TkqgDIfY2f0FSD+rU=";
  };
in
buildPythonPackage rec {
  pname = "seahub";
  inherit (source) version;

  src = source;

  format = "other";

  nativeBuildInputs = [
    python
    gettext
    python.pkgs.django
  ];
  propagatedBuildInputs = with python.pkgs; [
    ccnet-server
    django
    django-formtools
    django-picklefield
    django-post_office
    django-simple-captcha
    django-statici18n
    django-webpack-loader
    djangorestframework
    future
    gunicorn
    libsearpc
    openpyxl
    pillow
    pycryptodome
    pyjwt
    pymysql
    python-dateutil
    qrcode
    requests
    seafile-server
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
    mkdir -p $out/${python.sitePackages}
    ln -s $out/seahub $out/${python.sitePackages}/seahub
  '';

  passthru.pythonEnv = python.withPackages (p: [ p.seahub ]);

  meta = with stdenv.lib; {
    homepage = "https://github.com/haiwen/seahub";
    description = "Seahub is the web frontend for Seafile";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers;  [ b4dm4n ];
  };
}
