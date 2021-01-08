{ stdenv
, buildPythonPackage
, fetchPypi
, six
, django_appconf
}:

buildPythonPackage rec {
  pname = "django-statici18n";
  version = "1.9.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1l6iyijflhwhn9p7v1bygl3w88dqrys6r06vn4ly3jxbq5bd0gci";
  };

  propagatedBuildInputs = [ six django_appconf ];
}
