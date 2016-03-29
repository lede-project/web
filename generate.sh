#!/bin/sh

[ -d pages/ ] || {
	echo "Please execute as ./generate.sh" >&2
	exit 1
}

D="$(pwd)"

mkdir -p "$D/html"
find "$D/pages/" -type f | xargs -L1 a2x -f xhtml -r "$D/" -a "toc!" -a "numbered!" -D "$D/html/"
