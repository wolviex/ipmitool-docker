#!/bin/bash

set -e
set -x

die() {
	echo "$@"
	exit 1
}

verify() {
	while read type sum file ; do
		case "${type}" in
			AUX)
				echo "${sum}  ${AUXDIR}/${file}" | sha256sum -c
				;;
			SCRIPT)
				echo "${sum}  ${SCRIPTDIR}/${file}" | sha256sum -c
				;;
			SOURCE)
				echo "${sum}  ${SOURCEDIR}/${file}" | sha256sum -c
				;;
			*)
				die "Unknown manifest type '${type}'"
				;;
		esac
	done < "${SCRIPTDIR}"/Manifest
}

epatch() {
	for p in "${PATCHES[@]}" ; do
		local n f="${AUXDIR}/${p}"
		[ -f "${f}" ] || die "patch '${f}' not a file"
		for (( n=0 ; n < 5 ; n++ )) ; do
			patch -p$n < "${f}" && break
		done
		[ $? -eq 0 ] || die "applying '$f' failed"
	done
}

PN=ipmitool
PV=1.8.16
P="${PN}-${PV}"

SRC_URI="http://downloads.sourceforge.net/project/${PN}/${PN}/${PV}/${P}.tar.bz2"

PATCHES=(
	"ipmitool-1.8.16-imbapi-include-stddef-h.patch"
	"ipmitool-1.8.16-imbapi-include-socket-h.patch"
	"ipmitool-1.8.16-imbapi-pagesize.patch"
)

S="${WORKDIR}/${P}"
A="${SRC_URI##*/}"


cd "${SOURCEDIR}"

curl -L -o "${A}" "${SRC_URI}"

verify

cd "${WORKDIR}"

tar -xjf "${A}"

cd "${S}"
epatch
./configure --prefix=/usr
make
make install DESTDIR="${D}"
