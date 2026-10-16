{
  stdenv,
  lib,
  colord,
  desktop-file-utils,
  exiv2,
  fetchurl,
  gettext,
  giflib,
  glib,
  gnome,
  gst_all_1,
  gtk4,
  lcms2,
  libadwaita,
  libheif,
  libjpeg,
  libjxl,
  libpng,
  libportal,
  libportal-gtk4,
  libraw,
  librsvg,
  libtiff,
  libwebp,
  meson,
  ninja,
  pkg-config,
  shared-mime-info,
  vala,
  wrapGAppsHook4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gthumb";
  version = "4.0";

  src = fetchurl {
    url = "mirror://gnome/sources/gthumb/${lib.versions.majorMinor finalAttrs.version}/gthumb-${finalAttrs.version}.tar.xz";
    hash = "sha256-okqqcrVjf0kJfe3JwUGjNhXadw0CkxXzKF6/IVbPe2E=";
  };

  patches = [
    ./fix-tiff-exif-orientation-crash.patch
  ];

  strictDeps = true;

  nativeBuildInputs = [
    desktop-file-utils
    gettext
    meson
    ninja
    pkg-config
    vala
    wrapGAppsHook4
  ];

  buildInputs = [
    colord
    exiv2
    giflib
    glib
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-rs # for gtk4paintablesink
    gst_all_1.gst-plugins-ugly
    gtk4
    lcms2
    libadwaita
    libheif
    libjpeg
    libjxl
    libpng
    libportal
    libportal-gtk4
    libraw
    librsvg
    libtiff
    libwebp
  ];

  preFixup = ''
    gappsWrapperArgs+=(--prefix XDG_DATA_DIRS : "${shared-mime-info}/share")
  '';

  passthru = {
    updateScript = gnome.updateScript {
      packageName = "gthumb";
    };
  };

  meta = {
    homepage = "https://gitlab.gnome.org/GNOME/gthumb";
    description = "Image browser and viewer for GNOME";
    mainProgram = "gthumb";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [
      bobby285271
      mimame
    ];
  };
})
