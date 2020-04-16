# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="Google from the terminal"
HOMEPAGE="https://github.com/jarun/googler"
LICENSE="GPL-3+"
KEYWORDS="~amd64 ~arm ~mips ~mips64 ~ppc ~ppc64 ~x86"
SLOT="0"
MY_PV="$(ver_cut 1-2 ${PV})"
PYTHON_COMPAT=( python{3_6,3_7,3_8} )
inherit python-single-r1
RESTRICT="mirror"
EGIT_COMMIT="140f4d0bd28dbf143c801c339cbd490bf4dc54ed"
SRC_URI=\
"https://github.com/jarun/googler/archive/${EGIT_COMMIT}.tar.gz \
	-> ${P}.tar.gz"
inherit eutils
S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

src_prepare() {
	default
	export PREFIX="/usr"
	export DOCDIR="/usr/share/${P}"
	sed -i -e "s|/share/doc/googler|/share/doc/googler-${PVR}|" \
		Makefile || die
	sed -i -e "s|gzip|#gzip|" \
		-e "s|googler.1.gz|googler.1|g" Makefile || die
}
