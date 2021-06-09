{ lib
, stdenv
, fetchFromGitHub
, autoconf
, automake
, kmod
, libtool
, open-isns
, openssl
, perl
, pkg-config
, util-linux
, withSystemd ? true
, systemd ? null
}:

assert withSystemd -> systemd != null;

stdenv.mkDerivation rec {
  pname = "open-iscsi";
  version = "2.1.4";

  nativeBuildInputs = [ autoconf automake libtool perl pkg-config ];
  buildInputs = [ kmod open-isns openssl util-linux ]
    ++ lib.optionals withSystemd [ systemd ];

  src = fetchFromGitHub {
    owner = "open-iscsi";
    repo = "open-iscsi";
    rev = version;
    sha256 = "HnvLLwxOnu7Oiige6A6zk9NmAI2ImcILp9eCfbdGiyI=";
  };

  outputs = [ "out" "lib" "dev" "man" ];

  preConfigure = ''
    for f in usr/Makefile libopeniscsiusr/Makefile; do
      substituteInPlace $f --replace /usr/bin/pkg-config pkg-config
    done

    substituteInPlace Makefile --replace /usr /
  '';

  makeFlags = [
    "DESTDIR=${placeholder "out"}"
  ] ++ lib.optionals (!withSystemd) [
    "NO_SYSTEMD=1"
  ];

  enableParallelBuilding = true;

  installFlags = [
    "install"
    "install_udev_rules"
    "rulesdir=/lib/udev/rules.d"
  ] ++ lib.optionals withSystemd [
    "install_systemd"
  ];

  postInstall = ''
    for f in $out/sbin/iscsi_fw_login \
      $out/sbin/iscsi-gen-initiatorname \
      $out/lib/udev/rules.d/*.rules \
      ${lib.optionalString withSystemd "$out/lib/systemd/system/*.service"};
    do
      substituteInPlace $f --replace /sbin/ $out/bin/
    done

    mkdir -p $lib/lib
    mv -v $out/lib/lib* $lib/lib/
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    $out/bin/iscsistart -v
  '';

  meta = with lib; {
    description = "A high performance, transport independent, multi-platform implementation of RFC3720";
    license = licenses.gpl2Plus;
    homepage = "https://www.open-iscsi.com";
    platforms = platforms.linux;
    maintainers = with maintainers; [ cleverca22 zaninime ];
  };
}
