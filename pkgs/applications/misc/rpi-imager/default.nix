{ mkDerivation
, fetchFromGitHub
, lib
, cmake
, curl
, fetchpatch
, libarchive
, qtquickcontrols2
, qttools
, util-linux
}:

mkDerivation rec {
  pname = "rpi-imager";
  version = "1.5";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = pname;
    rev = "v${version}";
    sha256 = "0596c7rpkykmjr3gsz9yczqsj7fzq04kc97s0rqkygjnwiqh2rwz";
  };

  patches = [
    # Fix wayland crash
    (fetchpatch {
      url = "https://github.com/raspberrypi/rpi-imager/commit/2844b5bd1a058e0c401e4f96a0df4777b4a679f8.patch";
      sha256 = "0xx44knzs7md88qmmrd4fxs8n2mhpis822i967lx5w73235hpi0l";
    })
  ];

  postPatch = ''
    # lsblk can't run inside the sandbox
    substituteInPlace CMakeLists.txt --replace 'COMMAND "''${LSBLK}"' 'COMMAND "true"'
  '';

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    curl
    libarchive
    qtquickcontrols2
    qttools
    util-linux
  ];

  meta = with lib; {
    homepage = "https://github.com/raspberrypi/rpi-imager";
    description = "Raspberry Pi Imaging Utility";
    license = licenses.asl20;
    maintainers = with maintainers; [ b4dm4n ];
    platforms = platforms.unix;
  };
}
