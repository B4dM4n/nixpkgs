{
  lib,
  buildPythonPackage,
  cargo,
  cmake,
  fetchFromGitHub,
  fetchPypi,
  openssl,
  pkg-config,
  rustPlatform,
  rustc,
  setuptools-rust,
}:
buildPythonPackage (
  finalAttrs:
  let
    # Required by cpp/CMakeLists.txt with FetchContent_Declare
    abslSource = fetchFromGitHub {
      owner = "abseil";
      repo = "abseil-cpp";
      tag = "20250127.1";
      hash = "sha256-QTywqQCkyGFpdbtDBvUwz9bGXxbJs/qoFKF6zYAZUmQ=";
    };
  in
  {
    pname = "pyroscope-io";
    version = "1.2.5";
    pyproject = true;

    src = fetchPypi {
      pname = "pyroscope_io";
      inherit (finalAttrs) version;
      hash = "sha256-+pF4MxPIt6v7aYy4LgirMzkrdl6OtgPMQJRUyMaqnDc=";
    };

    postPatch = ''
      # We can't influence the cmake args, so patch the source
      substituteInPlace cpp/CMakeLists.txt \
        --replace-fail 'FetchContent_Declare(' \
          $'set(FETCHCONTENT_SOURCE_DIR_ABSL "${abslSource}" CACHE PATH "" FORCE)\nFetchContent_Declare('
    '';

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs)
        pname
        version
        src
        cargoRoot
        ;
      hash = "sha256-S2gUxR8MpUgLjAOTHs6ggleIW1dMSh/rWcN/TGyJQ50=";
    };
    cargoRoot = "rust";

    nativeBuildInputs = [
      cargo
      cmake
      pkg-config
      rustPlatform.cargoSetupHook
      rustc
      setuptools-rust
    ];

    buildInputs = [ openssl ];

    dontUseCmakeConfigure = true;

    pythonImportsCheck = [ "pyroscope" ];

    meta = {
      description = "Pyroscope Python integration";
      homepage = "https://github.com/grafana/pyroscope-python";
      changelog = "https://github.com/grafana/pyroscope-python/releases/tag/python-${finalAttrs.version}";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ b4dm4n ];
    };
  }
)
