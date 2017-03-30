# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit autotools java-pkg-opt-2 perl-functions

DESCRIPTION="Quick Database Manager"
HOMEPAGE="http://fallabs.com/qdbm/"
SRC_URI="http://fallabs.com/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="bzip2 cxx debug java lzo perl ruby zlib"

RDEPEND="bzip2? ( app-arch/bzip2 )
	java? ( >=virtual/jre-1.4:* )
	lzo? ( dev-libs/lzo )
	perl? ( dev-lang/perl )
	ruby? ( dev-lang/ruby:= )
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}
	java? ( >=virtual/jdk-1.4:* )"

PATCHES=(
	"${FILESDIR}"/${PN}-configure.patch
	"${FILESDIR}"/${PN}-perl.patch
	"${FILESDIR}"/${PN}-ruby19.patch
	"${FILESDIR}"/${PN}-runpath.patch
)
HTML_DOCS=( doc/. )

AT_NOELIBTOOLIZE="yes"

qdbm_foreach_api() {
	local u
	for u in cxx java perl ruby; do
		if ! use "${u}"; then
			continue
		fi
		einfo "${EBUILD_PHASE} ${u}"
		if [[ "${u}" == "cxx" ]]; then
			u="plus"
		fi
		cd "${u}"
		case "${EBUILD_PHASE}" in
		prepare)
			mv configure.{in,ac}
			eautoreconf
			;;
		configure)
			case "${u}" in
			cgi|java|plus)
				econf $(use_enable debug)
				;;
			*)
				econf
				;;
			esac
			;;
		compile)
			emake
			;;
		test)
			emake check
			;;
		install)
			emake DESTDIR="${D}" MYDATADIR=/usr/share/doc/${P}/html install
		esac
		cd - >/dev/null
	done
}

src_prepare() {
	default
	java-pkg-opt-2_src_prepare

	sed -i \
		-e "/^CFLAGS/s|$| ${CFLAGS}|" \
		-e "/^OPTIMIZE/s|$| ${CFLAGS}|" \
		-e "/^CXXFLAGS/s|$| ${CXXFLAGS}|" \
		-e "/^JAVACFLAGS/s|$| ${JAVACFLAGS}|" \
		-e 's/make\( \|$\)/$(MAKE)\1/g' \
		-e '/^debug/,/^$/s/LDFLAGS="[^"]*" //' \
		Makefile.in {cgi,java,perl,plus,ruby}/Makefile.in
	find -name "*~" -delete

	mv configure.{in,ac}
	eautoreconf
	qdbm_foreach_api
}

src_configure() {
	econf \
		$(use_enable bzip2 bzip) \
		$(use_enable debug) \
		$(use_enable lzo) \
		$(use_enable zlib) \
		--enable-iconv \
		--enable-pthread
	qdbm_foreach_api
}

src_compile() {
	default
	qdbm_foreach_api
}

src_test() {
	default
	qdbm_foreach_api
}

src_install() {
	default
	qdbm_foreach_api

	rm -rf "${ED}"/usr/share/${PN}

	if use java; then
		java-pkg_dojar "${ED}"/usr/$(get_libdir)/*.jar
		rm -f "${ED}"/usr/$(get_libdir)/*.jar
	fi
	if use perl; then
		perl_delete_module_manpages
		perl_fix_packlist
	fi

	rm -f "${ED}"/usr/bin/*test
	rm -f "${ED}"/usr/share/man/man1/*test.1*
}
