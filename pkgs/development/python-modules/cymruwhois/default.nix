{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "cymruwhois";
  version = "1.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0m7jgpglkjd0lsyw64lfw6qxdm0fg0f54145f79kq4rk1vjqbh5n";
  };

  doCheck = false;

  meta = with lib; {
    description = "Client for the whois.cymru.com service";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
