{ lib, stdenv, fetchurl, jre, makeWrapper, unzip }:

stdenv.mkDerivation rec {
  pname = "raritan-mpc";
  version = "7.0.3.5.62";

  src = fetchurl {
    url = "https://d3b2us605ptvk2.cloudfront.net/download/lx/v2.7.0/mpc-installer.MPC_${version}.jar.zip";
    sha256 = "1rn1k4kvf83y3q6cm9y8zplk63fzlv79vbkmmvlgndcxmvmxmgaa";
  };
  unpackCmd = "unzip $curSrc";
  sourceRoot = ".";

  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  nativeBuildInputs = [ unzip makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/opt/raritan-mpc
    echo INSTALL_PATH=$out/opt/raritan-mpc > installer.properties
    # the installer fails to call /bin/chmod, but it still extracts the required files, so ignore the error
    ${jre}/bin/java -jar mpc-installer.MPC_${version}.jar \
      -options installer.properties || :

    eval $(egrep -e '^java_parameters=' $out/opt/raritan-mpc/start.sh | sed -e "s| &'|'|")

    makeWrapper "${jre}/bin/java" "$out/bin/raritan-mpc" \
        --run "cd $out/opt/raritan-mpc/" \
        --add-flags "$java_parameters"

    # cleanup unneeded files
    rm -R $out/opt/raritan-mpc/{Uninstaller,start.sh,.installationinformation}
  '';

  meta = with lib; {
    description = "Java GUI client for the Raritan Dominion LX KVM";
    longDescription = ''
      Raritan Multi-Platform Client (MPC) and Raritan Remote Client (RRC) are graphical user
      interfaces for the Raritan Dominion KX and IP-Reach product lines, providing remote access to
      target servers connected to Raritan KVM over IP devices. Non-Windows users must use Raritan
      Multi-Platform Client, and Windows® users running Internet Explorer must use Raritan Remote
      Client.
    '';
    homepage = "https://www.raritan.com/support/product/dominion-lx/";
    maintainers = with maintainers; [ b4dm4n ];
    platforms = platforms.linux;
  };
}
