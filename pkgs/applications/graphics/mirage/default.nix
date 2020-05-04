{ stdenv, fetchurl, buildPythonApplication, pygtk, pillow, gettext }:

buildPythonApplication rec {
  pname = "mirage";
  version = "0.9.5.2";

  src = fetchurl {
    url = "mirror://sourceforge/mirageiv/${pname}-${version}.tar.bz2";
    sha256 = "d214a1b6d99d1d1e83da5848a2cef181f6781e0990e93f7ebff5880b0c43f43c";
  };

  patchPhase = ''
    sed -i "s@/usr/local/share/locale@$out/share/locale@" mirage.py
  '';

  nativeBuildInputs = [ gettext ];
  propagatedBuildInputs = [ pygtk pillow ];

  meta = with stdenv.lib; {
    description = "Simple image viewer written in PyGTK";
    homepage = "http://mirageiv.sourceforge.net/";
    license = licenses.gpl2;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
