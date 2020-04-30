{ stdenv
, buildPythonPackage
, fetchFromGitHub
, autoreconfHook
, curl
, libevent
, libsearpc
, libuuid
, pkg-config
, sqlite
, vala
, wrapPython
}:

buildPythonPackage rec {
  pname = "seafile-shared";
  version = "8.0.1";

  src = fetchFromGitHub {
    owner = "haiwen";
    repo = "seafile";
    rev = "v${version}";
    sha256 = "VKoGr3CTDFg3Q0X+MTlwa4BbfLB+28FeTyTJRCq37RA=";
  };

  format = "other";
  outputs = [ "out" "lib" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    vala
    pkg-config
    wrapPython
  ];

  buildInputs = [
    libuuid
    sqlite
    libsearpc
    libevent
    curl
  ];

  configureFlags = [
    "--disable-console"
  ];

  enableParallelBuilding = true;

  pythonPath = [
    libsearpc
  ];

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
}
