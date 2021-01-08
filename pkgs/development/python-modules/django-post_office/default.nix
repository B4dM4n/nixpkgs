{ stdenv
, buildPythonPackage
, fetchPypi
, django
, jsonfield
}:

buildPythonPackage rec {
  pname = "django-post_office";
  version = "3.2.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "195j6hw1zw11n263gs60gs1gkycyjk591xwla1bijxv45y12f973";
  };

  propagatedBuildInputs = [ django jsonfield ];

  doCheck = false;
}
