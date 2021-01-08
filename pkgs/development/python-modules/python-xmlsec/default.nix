{ buildPythonPackage
, lib
, fetchPypi
, xmlsec
, pkg-config
, pkgconfig
, libxml2
, libxslt
, libtool
, lxml
, pytest
, hypothesis
, setuptools_scm
, toml
, black
}:

buildPythonPackage rec {
  pname = "xmlsec";
  version = "1.3.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-PRPXtsuSHbxNYNAK0ACBoDjfc6Hmn1vMNpXesb8gk7A=";
  };

  nativeBuildInputs = [
    setuptools_scm
    toml
    # pkg-config
  ];

  buildInputs = [
    pkgconfig
    xmlsec
    libxml2
    libxslt
    lxml
    libtool
  ];

  checkInputs = [
    pytest
    hypothesis
    black
  ];

  postCheck = ''
    python -c 'import xmlsec'
  '';

  meta = with lib; {
    homepage = "https://github.com/mehcode/python-xmlsec";
    description = "Python bindings for the XML Security Library";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
