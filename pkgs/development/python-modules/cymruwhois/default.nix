{ lib
, buildPythonPackage
, fetchPypi
, nose
}:

buildPythonPackage rec {
  pname = "cymruwhois";
  version = "1.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-tsCF5Q4zEzzTcYUEUhx4DtTWseGOEsO9pqDJSd998lQ=";
  };

  checkInputs = [ nose ];

  meta = with lib; {
    description = "Client for the whois.cymru.com service";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
