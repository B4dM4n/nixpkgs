{ stdenv
, seafile-server
, seahub
}:
let
  python = seahub.python.withPackages (p: [ seahub ]);
in
stdenv.mkDerivation rec {
  pname = "seafile-server-scripts";
  inherit (seafile-server) version src;

  buildInputs = [
    python
  ];

  buildPhase = ''
    rm -R scripts/build scripts/upgrade/win32 scripts/*.bat

    while IFS= read -r -d $'\0' f; do
      isScript "$f" || sed -i '1 i\#!/usr/bin/env python' "$f"
      chmod +x "$f"
    done < <(find scripts -type f -name '*.py' -print0)
  '';

  installPhase = ''
    mv scripts $out
  '';
}
