# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils

DESCRIPTION="Godot"
HOMEPAGE="http://godotengine.org"
SRC_URI="https://github.com/godotengine/godot/archive/${PV:0:3}-beta.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="gamepad"

RDEPEND="dev-lang/python:2.7
	 media-libs/mesa
	 dev-libs/openssl
         gamepad? ( dev-libs/libevdev virtual/libudev )
         virtual/pkgconfig
         media-libs/freetype
         media-sound/pulseaudio
         dev-util/scons
         x11-libs/libXinerama
	 x11-libs/libX11
	 "
DEPEND="${RDEPEND}"

FEATURES="gamepad"

S="${WORKDIR}/godot-${PV:0:3}-beta"

src_compile() {
	scons platform=x11
}

src_install() {
	mkdir -p "${D}/usr/bin"
	cp "${S}/bin"/godot.*.tools.* "${D}/usr/bin"/

	PROG=$(ls "${D}/usr/bin"/godot.*.tools.*)
	PROG_BN=$(basename ${PROG})

	cd "${D}/usr/bin"
	ln -s "${PROG_BN}" "godot"
	mkdir -p "${D}/usr/share/godot"
	cp -r "${S}/demos"  "${D}/usr/share/godot"
}
