{ stdenv, fetchgit, writeShellScriptBin, readline, libbsd }:

let
  # only used to checkout the submodules, which are already downloaded by fetchgit
  fakeGit = writeShellScriptBin "git" "true";
in stdenv.mkDerivation rec {
  pname = "rosie";
  version = "1.2.1";

  src = fetchgit {
    url = "https://gitlab.com/rosie-pattern-language/rosie.git";
    rev = "v${version}";
    sha256 = "1fgp48q9xn8fc4zbpyc2issmmc6lrdsxpa93nk3xaj0qcj6kgz78";
    fetchSubmodules = true;
  };

  postPatch = ''
    patchShebangs src
  '';

  outputs = [ "out" "dev" "extra" ];

  nativeBuildInputs = [ fakeGit ];
  buildInputs = [ readline libbsd ];

  installPhase = ''
    make install DESTDIR="$out"
    rm $out/lib/rosie/build.log
    moveToOutput "include" "$dev"
    moveToOutput "lib/librosie.a" "$dev"
    moveToOutput "lib/rosie/doc" "$extra"
    moveToOutput "lib/rosie/extra" "$extra"
  '';

  meta = with stdenv.lib; {
    description = "Pattern matching language intended to replace regular expressions";
    homepage = "https://rosie-lang.org/";
    downloadPage = "https://gitlab.com/rosie-pattern-language/rosie";
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
    platforms = platforms.unix;
  };
}
