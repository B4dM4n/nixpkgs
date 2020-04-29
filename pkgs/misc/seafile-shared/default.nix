{ stdenv, fetchFromGitHub, which, autoreconfHook, pkgconfig, vala, python, curl, libevent, libsearpc, sqlite, libuuid }:
let
  libsearpc' = libsearpc.override { inherit python; };
in
python.pkgs.toPythonModule
  (stdenv.mkDerivation rec {
    pname = "seafile-shared";
    version = "7.0.7";

    src = fetchFromGitHub {
      owner = "haiwen";
      repo = "seafile";
      rev = "v${version}";
      sha256 = "0vgzb923x2q2w1zgbc56d50a5qj9xm77lg7czfzg3va7vd921gy8";
    };

    outputs = [ "out" "lib" "dev" ];

    nativeBuildInputs = [
      autoreconfHook
      vala
      pkgconfig
      python
      python.pkgs.wrapPython
    ];

    buildInputs = [
      libuuid
      sqlite
      libsearpc'
      libevent
      curl
    ];

    configureFlags = [ "--disable-console" ];

    enableParallelBuilding = true;

    pythonPath = [ libsearpc' ];

    postFixup = ''
      wrapPythonPrograms
    '';

    meta = with stdenv.lib; {
      homepage = "https://github.com/haiwen/seafile";
      description = "Shared components of Seafile: seafile-daemon, libseafile, libseafile python bindings, manuals, and icons";
      license = licenses.gpl3;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  })
