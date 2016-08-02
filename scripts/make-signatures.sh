#!/usr/bin/env bash

cat <<EOT > signatures.txt
---
---
LEDE Public Keys
================

== LEDE Public Keys

This page lists the fingerprints of all public keys in use by the LEDE project
and is automatically generated from the developer keys present in the
https://git.lede-project.org/?p=keyring.git[keyring.git] repository.

Refer to our link:signing.html[signing documentation page] to learn more about
file verification and key generation.

EOT

mkdir -p "tmp.$$/gpg" || {
	echo "Canot create temporary directory." >&2
	exit 1
}

trap "rm -fr tmp.$$" INT TERM
git clone https://git.lede-project.org/keyring.git "tmp.$$/git"


cat <<EOT >> signatures.txt
=== GnuPG key fingerprints

GnuPG keys are mainly used to verify the integrity of firmware image downloads.

Signature verification ensures that image downloads have not been tampered with
and that the third-party download mirrors serve genuine content.

EOT

format_key() {
	output=""

	while read field rest; do
		case $field in
			uid)
				output="User ID: $(echo "$rest" | sed -e 's/([^()]*) //; s/@/ -at- /; s/^\(.*\) </*\1* </') +\n$output"
			;;
			pub|sub)
				oIFS="$IFS"; IFS=" /]"; set -- $rest; IFS="$oIFS"
				type="$1"; keyid="$2"; created="$3"; expires="$5"

				case $field in
					pub) output="${output}Public Key: " ;;
					sub) output="${output}Signing Subkey: " ;;
				esac

				output="${output}*0x$keyid* ("

				case $type in
					*[rR]) output="${output}${type%[rR]} Bit RSA" ;;
					*[dD]) output="${output}${type%[dD]} Bit DSA" ;;
					*[gG]) output="${output}${type%[gG]} Bit ElGamal" ;;
				esac

				output="${output}, created $created${expires:+, expires $expires}) +\n";
			;;
			Key)
				fingerprint="${rest##* = }"
				output="${output}Fingerprint: +$fingerprint+ +\n"
			;;
		esac
	done

	printf "$output"
}

grep -rE "^Comment: " "tmp.$$/git/gpg"/*.asc | \
sed -e 's!^\([^:]*\):Comment: \(.*\)$!\2|\1!' | \
sort | \
while read line; do
	keyfile="${line##*|}"
	comment="${line%|*}"

	keyid=$(gpg --status-fd 1 --homedir "tmp.$$/gpg" --import "$keyfile" 2>/dev/null | \
		sed -ne 's!^.* IMPORTED \([A-F0-9]\+\) .*$!\1!p')

	relfile="gpg/${keyfile##*/gpg/}"
	modtime="$(cd "tmp.$$/git/"; git log -1 --format="%ci" -- "$relfile")"

	{
		cat <<-EOT
			---

			==== $comment
			$(gpg --homedir "tmp.$$/gpg" --fingerprint --fingerprint "$keyid" 2>/dev/null | format_key)

			[small]#https://git.lede-project.org/?p=keyring.git;a=history;f=$relfile[Last change: $modtime] | https://git.lede-project.org/?p=keyring.git;a=blob_plain;f=$relfile[Download]#

		EOT
	} >> signatures.txt
done

cat <<EOT >> signatures.txt
=== _usign_ public keys

The _usign_ EC keys are used to sign repository indexes in order to ensure that
packages fetched and installed via _opkg_ are unmodified and genuine.

Those keys are usually installed by default and bundled as
https://git.lede-project.org/?p=source.git;a=tree;f=package/system/lede-keyring[lede-keyring]
package.

EOT

grep -rE "^untrusted comment: " "tmp.$$/git/usign"/[a-f0-9]* | \
sed -e 's!^\([^:]*\):untrusted comment: \(.*\)$!\2|\1!' | \
sort | \
while read line; do
	keyfile="${line##*|}"
	comment="${line%|*}"

	relfile="usign/${keyfile##*/usign/}"
	modtime="$(cd "tmp.$$/git/"; git log -1 --format="%ci" -- "$relfile")"

	{
		cat <<-EOT
			---

			==== $comment
			 * Key-ID: +${keyfile##*/}+
			 * Key-Data: +$(grep -vE "^untrusted comment: " "$keyfile")+

			[small]#https://git.lede-project.org/?p=keyring.git;a=history;f=$relfile[Last change: $modtime] | https://git.lede-project.org/?p=keyring.git;a=blob_plain;f=$relfile[Download]#

		EOT
	} >> signatures.txt
done

rm -fr "tmp.$$"
