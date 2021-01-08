{ stdenv
, buildPythonPackage
, fetchPypi
, django
}:

buildPythonPackage rec {
  pname = "django-formtools";
  version = "2.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1chkbl188yj6hvhh1wgjpfgql553k6hrfwxzb8vv4lfdq41jq9y5";
  };

  propagatedBuildInputs = [ django ];

  doCheck = false;
}
