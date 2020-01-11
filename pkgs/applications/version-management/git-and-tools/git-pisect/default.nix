{ stdenv, fetchFromGitHub, makeWrapper, perlPackages, runCommand }:

let
  inherit (perlPackages) perl makeFullPerlPath ListMoreUtils SysInfo;

  perlWithPackages = packages:
      runCommand "perl-with-packages" { buildInputs = [ makeWrapper ]; } ''
        makeWrapper "${perl}/bin/perl" "$out/bin/perl" --argv0 '$0' \
          --prefix PERL5LIB : ${makeFullPerlPath packages}
      '';

in stdenv.mkDerivation rec {
  pname = "git-pisect";
  version = "unstable-20161124";

  src = fetchFromGitHub {
    owner = "hoelzro";
    repo = "${pname}";
    rev = "47926e31bacdd6fb6a088ad5af4856b0f0f878d8";
    sha256 = "0qavai5ms8wlk8qn0vj4x23c67w2r8z7prdnvfv4y0px55shvs5b";
  };

  buildInputs = [ (perlWithPackages [ ListMoreUtils SysInfo ]) ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 555 git-pisect $out/bin
    patchShebangsAuto
  '';

  meta = with stdenv.lib; {
    description = "An alternative to git bisect run that uses multiple concurrent tests";
    inherit (src.meta) homepage;
    license = licenses.mit;
    maintainers = with maintainers; [ b4dm4n ];
    platforms = platforms.linux;
  };
}
