{ stdenv
, mkDerivation
, fetchFromGitHub
, cmake
, pkgconfig

, qtbase
, qttools
, qtsvg

, exiv2
, opencv
, libraw
, libtiff
, quazip
, enablePlugins ? true
}:

let
  inherit (stdenv.lib) optional optionalString;
in
mkDerivation rec {
  pname = "nomacs";
  version = "3.12";

  src = [
    (fetchFromGitHub {
      owner = "nomacs";
      repo = "nomacs";
      name = "nomacs";
      rev = version;
      sha256 = "12582i5v85da7vwjxj8grj99hxg34ij5cn3b1578wspdfw1xfy1i";
    })
  ] ++ optional enablePlugins (fetchFromGitHub {
    owner = "nomacs";
    repo = "nomacs-plugins";
    name = "nomacs-plugins";
    rev = "3.12.0";
    sha256 = "163dfm8w6wy4q2rax7rn4nvajgwvf7b94bchq5404i8ykcc35sdm";
  });

  patches = [
    ./nomacs-iostream.patch
  ];
  postPatch = optionalString enablePlugins ''
    ln -s ../../nomacs-plugins plugins
  '';

  enableParallelBuilding = true;

  setSourceRoot = ''
    sourceRoot=$(echo */ImageLounge)
  '';

  nativeBuildInputs = [cmake
                       pkgconfig];

  buildInputs = [qtbase
                 qttools
                 qtsvg
                 exiv2
                 opencv
                 libraw
                 libtiff
                 quazip];

  cmakeFlags = ["-DENABLE_OPENCV=ON"
                "-DENABLE_RAW=ON"
                "-DENABLE_TIFF=ON"
                "-DENABLE_QUAZIP=ON"
                "-DENABLE_TRANSLATIONS=ON"
                "-DUSE_SYSTEM_QUAZIP=ON"
                "-DENABLE_PLUGINS=${if enablePlugins then "ON" else "OFF"}"];

  meta = with stdenv.lib; {
    homepage = https://nomacs.org;
    description = "Qt-based image viewer";
    maintainers = with maintainers; [ ahmedtd b4dm4n ];
    license = licenses.gpl3Plus;
    repositories.git = https://github.com/nomacs/nomacs.git;
    inherit (qtbase.meta) platforms;
  };
}
