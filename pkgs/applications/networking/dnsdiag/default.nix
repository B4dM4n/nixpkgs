{ lib, python3Packages }:

with python3Packages;
buildPythonApplication rec {
  pname = "dnsdiag";
  version = "1.7.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0qh5fwgzbqs9xncq3zw8nb1zhiqyb2wvr4k0qda80gmjamzf829b";
  };

  outputs =  ["out" "share"];

  propagatedBuildInputs = [ dnspython cymruwhois ];

  postInstall = ''
    # Turn the misplaced "scripts" into modules
    mkdir -p $out/${python.sitePackages}
    mv $out/bin/*.py $out/${python.sitePackages}

    # Copy provided DNS server lists
    install -D -t $share/share/dnsdiag *.txt
  '';

  meta = with lib; {
    description = "DNS Diagnostics and measurement tools (ping, traceroute)";
    license = licenses.bsd2;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
