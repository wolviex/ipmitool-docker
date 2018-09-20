#!/bin/bash

set -e

USAGE="$0 <command>"
USAGE_build="$0 build <package>"

die() {
	local error="${*:-(unknown)}"
	echo "Error: ${error} in ${FUNCNAME[1]}() at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" > /dev/stderr
	exit 1
}

has() {
	local flag="$1" ; shift
	for f in "$@" ; do
		[[ "${f}" = "${flag}" ]] && return 0
	done
	return 1
}

verify_source() {
	local MANIFEST="$1" ; shift
	[[ "${MANIFEST}" ]] || die

	local SOURCE="$1" ; shift
	if [[ "${SOURCE}" ]] ; then
		if ! test -f "${SOURCE}" ; then
			return 1
		fi

		while read type file size sha256sum ; do
			case "${type}" in
				SOURCE)
					if [[ "${file}" = "${SOURCE}" ]] ; then
						actual_size=$(file_size "${file}")
						if [[ "${actual_size}" -ne "${size}" ]] ; then
							return 1
						elif ! echo "${sha256sum}  ${CACHEDIR}/${file}" | sha256sum -c ; then
							return 1
						fi
					fi
					;;
			esac
		done < "${MANIFEST}"

		return 0
	fi

	local uri file
	for uri in "${SOURCES[@]}" ; do
		file="${CACHEDIR}/${uri##*/}"
		verify_source "${MANIFEST}" "${file}"
	done
}

verify_manifest() {
	while read type file size sha256sum ; do
		case "${type}" in
			AUX)
				echo "${sha256sum}  ${AUXDIR}/${file}" | sha256sum -c
				;;
			SCRIPT)
				echo "${sha256sum}  ${SCRIPTDIR}/${file}" | sha256sum -c
				;;
			SOURCE)
				if has "${file}" "${SOURCES[@]}" ; then
					echo "${sha256sum}  ${CACHEDIR}/${file}" | sha256sum -c
				fi
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

pkg_install() {
	rsync -av "${D}/" "${ROOT}/"
}

split_package_name_version() {
	P="$1" ; shift
	test -n "${P}" || die

	PN="${P%%-[0-9]*}"
	PV="${P##${PN}-}"
}

set_package_env() {
	local SCRIPTFILE="$1" ; shift
	test -n "${SCRIPTFILE}" || die

	P="$(basename ${SCRIPTFILE} .build)"
	split_package_name_version "${P}"
}

build() {
	P="$1" ; shift
	test -n "${P}" || die "${USAGE_build}"

	split_package_name_version "${P}"

	local SCRIPTFILE="${SCRIPTDIR}/${P}.build"
	test -f "${SCRIPTFILE}" || die "${SCRIPTFILE} not found!"

	source "${SCRIPTFILE}"
	test -n "${EAPI}" || die "${SCRIPTFILE} needs to set EAPI!"
	source "${MYDIR}/pkg-api-${EAPI}.sh"

	src_fetch
	verify_manifest
	src_unpack
	src_prepare
	set -x
	src_configure
	src_compile
	src_install
	set +x
	pkg_install
}

file_size() {
	local file="$1" ; shift
	du --bytes "${file}" | cut -d$'\t' -f1
}

file_sha256sum() {
	local file="$1" ; shift
	sha256sum "${file}" | cut -d' ' -f1
}

sources_manifest() {
	local MANIFESTFILE="$1" ; shift
	test -f "${MANIFESTFILE}" || die

	local SCRIPTFILE="$1" ; shift
	test -f "${SCRIPTFILE}" || die

	set_package_env "${SCRIPTFILE}"

	source "${SCRIPTFILE}"
	test -n "${EAPI}" || die "${SCRIPTFILE} needs to set EAPI!"
	source "${MYDIR}/pkg-api-${EAPI}.sh"

	src_fetch

	local uri file
	for uri in "${SOURCES[@]}" ; do
		file="${CACHEDIR}/${uri##*/}"
		size=$(file_size "${file}")
		sha256sum=$(file_sha256sum "${file}")
		echo "SOURCE  $(basename ${file})  ${size}  ${sha256sum}" >> "${MANIFESTFILE}"
	done
}

manifest() {
	local MANIFESTFILE="${SCRIPTDIR}"/Manifest

	sed -i "${MANIFESTFILE}" \
		-e '/^AUX  /d' \
		-e '/^SCRIPT  /d' \
		-e '/^SOURCE  /d'

	for f in "${SCRIPTDIR}"/*.build ; do
		if ! test -f "${f}" ; then
			break
		fi

		size=$(file_size "${f}")
		sha256sum=$(file_sha256sum "${f}")
		echo "SCRIPT  $(basename ${f})  ${size}  ${sha256sum}" >> "${MANIFESTFILE}"
		sources_manifest "${MANIFESTFILE}" "${f}"
	done

	for f in "${AUXDIR}"/* ; do
		if ! test -f "${f}" ; then
			break
		fi

		size=$(file_size "${f}")
		sha256sum=$(file_sha256sum "${f}")
		echo "AUX  $(basename ${f})  ${size}  ${sha256sum}" >> "${MANIFESTFILE}"
	done
}

command() {
	local command="$1" ; shift

	case "${command}" in
		build) build "$@" ;;
		manifest) manifest "$@" ;;
		*) die "${USAGE}" ;;
	esac
}

CACHEDIR="${HOME}/.cache/tinypkg"
MYDIR="$(cd $(dirname $0) && echo ${PWD})"
SCRIPTDIR="${MYDIR}/script"
AUXDIR="${SCRIPTDIR}/aux"

mkdir -p "${CACHEDIR}"

command "$@"
