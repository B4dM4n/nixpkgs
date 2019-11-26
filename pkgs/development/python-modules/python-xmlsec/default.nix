{ buildPythonPackage, lib, fetchPypi, xmlsec, pkgconfig, libxml2, libxslt, libtool, lxml }:

buildPythonPackage rec {
  pname = "xmlsec";
  version = "1.3.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1mlysa6ld9l9a8w78m01c6kzmq6lxicd3zvlv0ik55vl44bw0wz5";
  };

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ xmlsec libxml2 libxslt lxml libtool ];

  checkPhase = ''
    python -c 'import xmlsec'
  '';

  meta = with lib; {
    homepage = "https://github.com/mehcode/python-xmlsec";
    description = "Python bindings for the XML Security Library";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
