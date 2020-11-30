{ stdenv, fetchFromGitHub, pkgconfig, makeWrapper, makeDesktopItem
, ncurses, libtermkey, lpeg, lua
, acl ? null, libselinux ? null
}:

stdenv.mkDerivation rec {
  pname = "vis";
  version  = "0.6";

  src = fetchFromGitHub {
    rev = "v${version}";
    sha256 = "1zjm89cn3rfq8fxpwp66khy53s6vqlmw6q103qyyvix8ydzxdmsh";
    repo = "vis";
    owner = "martanne";
  };

  nativeBuildInputs = [ pkgconfig makeWrapper ];

  buildInputs = let
    desktopItem = makeDesktopItem {
      name = "vis";
      exec = "vis %U";
      type = "Application";
      icon = "accessories-text-editor";
      comment = meta.description;
      desktopName = "vis";
      genericName = "Text editor";
      categories = stdenv.lib.concatStringsSep ";" [
        "Application" "Development" "IDE"
      ];
      mimeType = stdenv.lib.concatStringsSep ";" [
        "text/plain" "application/octet-stream"
      ];
      startupNotify = "false";
      terminal = "true";
    };
  in
  [
    desktopItem
    ncurses
    libtermkey
    lua
    lpeg
  ] ++ stdenv.lib.optionals stdenv.isLinux [
    acl
    libselinux
  ];

  postPatch = ''
    patchShebangs ./configure
  '';

  LUA_CPATH="${lpeg}/lib/lua/${lua.luaversion}/?.so;";
  LUA_PATH="${lpeg}/share/lua/${lua.luaversion}/?.lua";

  postInstall = ''
    echo wrapping $out/bin/vis with runtime environment
    wrapProgram $out/bin/vis \
      --prefix LUA_CPATH ';' "${lpeg}/lib/lua/${lua.luaversion}/?.so" \
      --prefix LUA_PATH ';' "${lpeg}/share/lua/${lua.luaversion}/?.lua" \
      --prefix VIS_PATH : "\$HOME/.config:$out/share/vis"
  '';

  meta = with stdenv.lib; {
    description = "A vim like editor";
    homepage = "https://github.com/martanne/vis";
    license = licenses.isc;
    maintainers = with maintainers; [ vrthra ramkromberg ];
    platforms = platforms.unix;
  };
}
