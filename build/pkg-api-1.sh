S="${WORKDIR}/${P}"
B="${S}_build"

src_fetch() {
	local uri file
	cd "${CACHEDIR}"
	for uri in "${SOURCES[@]}" ; do
		file="${uri##*/}"
		echo "* Fetching: ${file} ..."
		if ! verify_source "${file}" ; then
			curl --fail --silent --show-error --location --output "${file}" "${uri}"
		fi
	done
}

src_unpack() {
	local uri file
	cd "${WORKDIR}"
	for uri in "${SOURCES[@]}" ; do
		file="${CACHEDIR}/${uri##*/}"
		echo "* Unpacking: ${file} ..."
		case "${file}" in
			*.gz) tar -xzf "${file}" ;;
			*.bz2) tar -xjf "${file}" ;;
			*.xz) tar -xJf "${file}" ;;
			*) die "Unsupported file format: ${file}" ;;
		esac
	done
}

src_prepare() {
	cd "${S}"
	epatch
}

src_configure() {
	mkdir "${B}"
	cd "${B}"
	"${S}"/configure
}

src_compile() {
	cd "${B}"
	make
}

src_install() {
	cd "${B}"
	make install DESTDIR="${D}"
}
