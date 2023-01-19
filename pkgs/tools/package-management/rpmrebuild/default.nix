{ stdenv
, lib
, fetchurl
, bash
, rpm
, makeWrapper
}:

with lib;
stdenv.mkDerivation rec {
  pname = "rpmrebuild";
  version = "2.16";

  src = fetchurl {
    url = "mirror://sourceforge/${pname}/${pname}-${version}.tar.gz";
    sha256 = "uKmDCmxAQGZ9DHiwJegNBG7J9Rr7UV3HiC8kLkCV804=";
  };

  sourceRoot = ".";

  patches = [ ./absolute_paths.patch ];
  postPatch = ''
    substituteAllInPlace rpmrebuild
  '';

  buildInputs = [ makeWrapper ];

  installFlags = "DESTDIR=$(out)";
  postInstall = ''
    wrapProgram "$out/bin/rpmrebuild" \
      --prefix PATH : "${makeBinPath [ bash rpm ]}"
  '';

  meta = {
    description = "A tool to build an RPM file from a package that has already been installed";
    homepage = "https://sourceforge.net/projects/rpmrebuild";
    license = licenses.gpl2;
    maintainers = with maintainers; [ b4dm4n ];
    platforms = platforms.linux;
  };
}
