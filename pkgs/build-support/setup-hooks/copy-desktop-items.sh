# shellcheck shell=bash

# Setup hook that installs specified desktop items.
#
# Example usage in a derivation:
#
#   { …, makeDesktopItem, copyDesktopItems, … }:
#
#   let desktopItem = makeDesktopItem { … }; in
#   stdenv.mkDerivation {
#     …
#     nativeBuildInputs = [ copyDesktopItems ];
#
#     desktopItems =  [ desktopItem ];
#     …
#   }
#
# This hook will copy files which are either given by full path
# or all '*.desktop' files placed inside the 'share/applications'
# folder of each `desktopItems` argument.

postInstallHooks+=(copyDesktopItems)

copyDesktopItems() {
    [[ ${dontCopyDesktopItems:-} == 1 || -z ${desktopItems:-} ]] && return

    for desktopItem in $desktopItems; do
        if [[ -f "$desktopItem" ]]; then
            filename=$(stripHash "$desktopItem")
            echo "Copying '$desktopItem' to '$out/share/applications/$filename'"
            install -D -m 444 "$desktopItem" "$out/share/applications/$filename"
        else
            for f in "$desktopItem"/share/applications/*.desktop; do
                echo "Copying '$f' into '$out/share/applications'"
                install -D -m 444 -t "$out"/share/applications "$f"
            done
        fi
    done
}
