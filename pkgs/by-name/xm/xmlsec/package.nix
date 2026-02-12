{
  stdenv,
  fetchurl,
  fetchpatch,
  libxml2,
  gnutls,
  libxslt,
  pkg-config,
  libgcrypt,
  libtool,
  openssl,
  nss,
  lib,
  runCommandCC,
  writeText,
  enableLegacyFeatures ? false,
  xmlsec,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xmlsec";
  version = "1.3.9";

  src = fetchurl {
    urls = [
      "https://www.aleksey.com/xmlsec/download/xmlsec1-${finalAttrs.version}.tar.gz"

      # for when the ${finalAttrs.version} gets older than the last two
      "https://www.aleksey.com/xmlsec/download/older-releases/xmlsec1-${finalAttrs.version}.tar.gz"
    ];
    hash = "sha256-pjHIzXprhuatufW5NdRanPl2izywkNRh6OudBDz5ti8=";
  };

  patches = [
    ./lt_dladdsearchdir.patch
    ./remove_bsd_base64_decode_flag.patch
  ];

  postPatch = ''
    substituteAllInPlace src/dl.c
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libxml2
    gnutls
    libtool
    openssl
    nss
  ]
  ++ lib.optionals enableLegacyFeatures [
    libgcrypt
  ];

  propagatedBuildInputs = [
    # required by xmlsec/transforms.h
    libxslt
  ];

  enableParallelBuilding = true;
  doCheck = true;
  nativeCheckInputs = [ nss.tools ];
  preCheck = ''
    export TMPFOLDER=$(mktemp -d)
    substituteInPlace tests/testrun.sh \
      --replace-fail 'timestamp=`date +%Y%m%d_%H%M%S`' 'timestamp=19700101_000000'
  '';

  # allow to enable old algorithms and engines, disabled in v1.3.7 by default
  configureFlags = lib.optionals enableLegacyFeatures [ "--enable-legacy-features" ];

  postInstall = ''
    moveToOutput "bin/xmlsec1-config" "$dev"
    moveToOutput "lib/xmlsec1Conf.sh" "$dev"
  '';

  passthru.tests.libxmlsec1-crypto =
    runCommandCC "libxmlsec1-crypto-test"
      {
        nativeBuildInputs = [
          pkg-config
        ];
        buildInputs = [
          finalAttrs.finalPackage
          libxml2
          libxslt
          libtool
        ];
      }
      ''
        $CC $(pkg-config --cflags --libs xmlsec1) -o crypto-test ${writeText "crypto-test.c" ''
          #include <xmlsec/xmlsec.h>
          #include <xmlsec/crypto.h>

          int main(int argc, char **argv) {
            return xmlSecInit() ||
              xmlSecCryptoDLLoadLibrary(argc > 1 ? argv[1] : 0) ||
              xmlSecCryptoInit();
          }
        ''}

        for crypto in "" gnutls nss openssl ${lib.optionalString enableLegacyFeatures "gcrypt"}; do
          ./crypto-test $crypto
        done
        touch $out
      '';

  # Also build the test with legacy features enabled. Need to override the xmlsec attribute,
  # since finalAttrs does not provide override.
  passthru.tests.libxmlsec1-crypto-with-legacy =
    (xmlsec.override { enableLegacyFeatures = true; }).tests.libxmlsec1-crypto;

  meta = {
    description = "XML Security Library in C based on libxml2";
    homepage = "https://www.aleksey.com/xmlsec/";
    downloadPage = "https://www.aleksey.com/xmlsec/download.html";
    license = lib.licenses.mit;
    mainProgram = "xmlsec1";
    maintainers = with lib.maintainers; [ b4dm4n ];
    platforms = with lib.platforms; linux ++ darwin;
  };
})
