{ stdenv, buildPythonPackage, fetchPypi, python, pytest, cffi, rosie }:

buildPythonPackage rec {
  pname = "rosie";
  version = "1.1.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1syqrg5c2albx9rzqmdhd6qrmy5hp57n3f67zq4nh1g7vsh9wjyk";
  };

  checkInputs = [ pytest ];
  propagatedBuildInputs = [ cffi ];

  postPatch = ''
    # remove unneeded cache files
    find -name '*.pyc' -delete
    # set global librosie path
    substituteInPlace rosie/internal.py \
      --replace "_load_from(''')" '_load_from("${rosie}/lib")'
  '';

  checkPhase = ''
    cd test
    ${python}/bin/python test.py system
  '';

  meta = with stdenv.lib; {
    description = "Rosie Pattern Language (replaces regex for data mining and text search)";
    homepage = "https://rosie-lang.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
