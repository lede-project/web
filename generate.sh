#!/bin/sh

[ -d pages/ ] || {
	echo "Please execute as ./generate.sh" >&2
	exit 1
}

D="$(pwd)"
O="-b html5 -a linkcss -a stylesdir=/css -a stylesheet=lede.css -a disable-javascript -a icons -a iconsdir=/icon"

copy() {(
	cd "$1"
	find . -type f | while read path; do
		dest="$2/${path#./}"
		mkdir -p "${dest%/*}"
		cp -a "$path" "$dest"
	done
)}

render() {(
	find "$1" -type f -name '*.txt' | while read path; do
		dest="$2/${path#$1/}"
		dest="${dest%.txt}.html"
		mkdir -p "${dest%/*}"
		asciidoc $O -o "$dest" "$path"
	done
)}

copy "$D/logo" "$D/html/logo"
copy "$D/css" "$D/html/css"
copy "$D/icon" "$D/html/icon"

render "$D/pages" "$D/html"
render "$D/docs" "$D/html/docs"
