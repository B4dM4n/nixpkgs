{ stdenv, fetchurl, bash, rpm, makeWrapper }:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "rpmrebuild";
  version = "2.14";

  src = fetchurl {
    url = "mirror://sourceforge/${pname}/${pname}-${version}.tar.gz";
    sha256 = "0fcwshb2n25vqaz7k6f0h3hscvz9lqy23nqmvsrw32kiidf3i6dy";
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
    platforms = platforms.linux ++ platforms.darwin;
  };
}
