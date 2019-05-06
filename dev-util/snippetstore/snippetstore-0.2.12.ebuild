# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

RDEPEND="${RDEPEND}
	 >=dev-util/electron-1.8.8"

DEPEND="${RDEPEND}
        net-libs/nodejs[npm]"

inherit eutils desktop electron-app

MY_PN="SnippetStore"
DESCRIPTION="A snippet management app for developers"
HOMEPAGE="https://zerox-dg.github.io/SnippetStoreWeb/"
SRC_URI="https://github.com/ZeroX-DG/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

S="${WORKDIR}/${MY_PN}-${PV}"

TAR_V="^4.4.2"

_fix_vulnerabilities() {
	pushd node_modules/node-gyp
	npm uninstall tar
	npm uninstall tar@"${TAR_V}"
	popd
}

electron-app_src_postprepare() {
	_fix_vulnerabilities
}

electron-app_src_compile() {
	cd "${S}"

	export PATH="${S}/node_modules/.bin:${PATH}"
	npm run build || die

	rm -rf dist/ # same as `rimraf dist/` in package.json

	# This is required for compleness and for the program to run properly.
	# We deviate since we are not building for other distros.
	electron-builder -l dir || die
}

src_install() {
	electron-app_desktop_install "*" "resources/icon/icon512.png" "${MY_PN}" "Development" "/usr/$(get_libdir)/node/${PN}/${SLOT}/dist/linux-unpacked/snippetstore"
}
