# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

RDEPEND="${RDEPEND}
	 >=dev-util/electron-2.0.3"

DEPEND="${RDEPEND}
        net-libs/nodejs[npm]"

inherit eutils desktop electron-app

DESCRIPTION="Unofficial Instagram Desktop App"
HOMEPAGE="https://github.com/terkelg/ramme"
SRC_URI="https://github.com/terkelg/ramme/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="-analytics-tracking"

S="${WORKDIR}/${PN}-${PV}"
RESTRICT="userpriv" # workaround _lock error

src_prepare() {
	default

	if ! use analytics-tracking ; then
		epatch "${FILESDIR}"/${PN}-3.2.5-disable-analytics.patch
		rm "${S}"/app/src/main/analytics.js
	fi

	# fix stall bug in sandbox
	sed -i -e "s|\"electron\": \"\^2.0.3\",||g" package.json || die

	npm install yarn || die
	electron-app-fetch-deps
}

src_compile() {
	electron-app_src_compile
	npm uninstall yarn || die
	cd "${S}/app"
	npm install electron-config || die
}

src_install() {
	electron-desktop-app-install "*" "app" "media/icon.png" "${PN^}" "Network"
}
