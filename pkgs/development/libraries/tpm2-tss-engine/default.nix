{ lib
, mkDerivation
, fetchFromGitHub
, autoconf-archive
, autoreconfHook
, cmocka
, expect
, ibm-sw-tpm2
, iproute
, openssl
, pandoc
, pkg-config
, tpm2-tools
, tpm2-tss
}:

mkDerivation rec {
  pname = "tpm2-tss-engine";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "tpm2-software";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-iKqGBc6v7FUpwu4+BgmstBgBCw2Ksd/H0aDM+SMajN8=";
  };

  nativeBuildInputs = [
    autoconf-archive
    autoreconfHook
    pandoc
    pkg-config
  ];

  buildInputs = [
    openssl
    tpm2-tss
  ];

  checkInputs = [
    cmocka
    expect
    ibm-sw-tpm2
    iproute
    tpm2-tools
  ];

  enableParallelBuilding = true;

  postPatch = "patchShebangs test";

  configureFlags = [
    "--with-enginesdir=${placeholder "out"}/lib/engines"
    "--enable-unit"
    "--enable-integration"
  ];

  preCheck = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ tpm2-tss ]}"
  '';

  doCheck = true;

  meta = with lib; {
    description = "OSS implementation of the TCG TPM2 Software Stack (TSS2)";
    homepage = "https://github.com/tpm2-software/tpm2-tss-engine";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
