{ stdenv, fetchFromGitHub, which, autoreconfHook, pkgconfig, vala, python, curl, libevent, libsearpc, sqlite, libuuid }:
stdenv.mkDerivation rec {
  pname = "seafile-shared";
  version = "7.0.6";

  src = fetchFromGitHub {
    owner = "haiwen";
    repo = "seafile";
    rev = "v${version}";
    sha256 = "0pc6xbwxljpj7h37za63kspdi90ap58x6x5b7hsmlhahblvlw0b8";
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
    libsearpc
    libevent
    curl
  ];

  configureFlags = [ "--disable-console" ];

  enableParallelBuilding = true;

  pythonPath = [ libsearpc ];

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
