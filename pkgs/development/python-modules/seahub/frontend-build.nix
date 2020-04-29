{ stdenv, nodejs, source, sha256 }:

stdenv.mkDerivation {
  pname = "seahub-frontend-build";
  inherit (source) version;
  src = source.frontend;

  nativeBuildInputs = [ nodejs ];

  phases = "unpackPhase patchPhase buildPhase installPhase";

  buildPhase = ''
    if [[ ! -f package-lock.json ]]; then
      echo
      echo "ERROR: The package-lock.json file doesn't exist"
      echo

      exit 1
    fi

    export HOME=$(mktemp -d home.XXXXXX)
    npm install
    npm run-script build
  '';

  installPhase = ''
    mv build $out
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = sha256;

  impureEnvVars = stdenv.lib.fetchers.proxyImpureEnvVars;
}
