{ atomEnv
, autoPatchelfHook
, dpkg
, fetchurl
, makeDesktopItem
, makeWrapper
, lib
, stdenv
, udev
, wrapGAppsHook
}:

let
  inherit (stdenv.hostPlatform) system;

  throwSystem = throw "Unsupported system: ${system}";

  pname = "simplenote";

  version = "2.1.0";

  sha256 = {
    x86_64-linux = "0lg48nq493anpnm20vw72y242nxa1g903bxzp4pngzxyi986jddz";
  }.${system} or throwSystem;

  meta = with stdenv.lib; {
    description = "The simplest way to keep notes";
    homepage = "https://github.com/Automattic/simplenote-electron";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      kiwi
    ];
    platforms = [
      "x86_64-linux"
    ];
  };

  desktopItem = makeDesktopItem {
    categories = "Development";
    comment = "Simplenote for Linux";
    desktopName = "Simplenote";
    exec = "simplenote %U";
    icon = "simplenote";
    name = "simplenote";
    startupNotify = "true";
    type = "Application";
  };

  linux = stdenv.mkDerivation rec {
    inherit pname version meta;

    src = fetchurl {
      url =
        "https://github.com/Automattic/simplenote-electron/releases/download/"
        + "v${version}/Simplenote-linux-${version}-amd64.deb";
      inherit sha256;
    };

    dontBuild = true;
    dontConfigure = true;
    dontPatchELF = true;
    dontWrapGApps = true;

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook
    ];

    buildInputs = [ desktopItem ] ++ atomEnv.packages;

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      mkdir -p "$out/bin"
      cp -R "opt" "$out"
      cp -R "usr/share" "$out/share"
      chmod -R g-w "$out"
    '';

    runtimeDependencies = [
      (lib.getLib udev)
    ];

    postFixup = ''
      makeWrapper $out/opt/Simplenote/simplenote $out/bin/simplenote \
        --prefix LD_LIBRARY_PATH : "${stdenv.lib.makeLibraryPath [ stdenv.cc.cc ] }" \
        "''${gappsWrapperArgs[@]}"
    '';
  };

in
linux
