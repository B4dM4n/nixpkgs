{ lib, python3Packages }:

with python3Packages;
buildPythonApplication rec {
  pname = "dnsdiag";
  version = "2.0.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-aJzc9LzrQEU5mHChvZC3xmb53VDfSwqMd4M1PgKE3ss=";
  };

  patches = [
    # Backport of https://github.com/farrokhi/dnsdiag/pull/93
    ./fix-orange-color.patch
  ];

  propagatedBuildInputs = [
    cymruwhois
    dnspython
    requests-toolbelt
  ];

  postInstall = ''
    # Turn the misplaced "scripts" into modules
    mkdir -p $out/${python.sitePackages}
    mv $out/bin/*.py $out/${python.sitePackages}

    # Copy provided DNS server lists
    install -D -t $out/share/dnsdiag public-servers.txt public-v4.txt rootservers.txt
  '';

  meta = with lib; {
    description = "DNS Diagnostics and measurement tools (ping, traceroute)";
    license = licenses.bsd2;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
