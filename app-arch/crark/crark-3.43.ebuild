# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

inherit eutils

DESCRIPTION="Fastest freeware utility to crack RAR password"
HOMEPAGE="http://www.crark.net/"
SRC_URI="opencl? ( http://www.crark.net/download/crark34-linux-opencl.rar )
         cpu? ( http://www.crark.net/download/crark34-linux.rar )
         cuda? ( http://www.crark.net/download/crark34-linux-cuda.rar )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="opencl cuda cpu"
IUSE+=" video_cards_fglrx video_cards_amdgpu"
REQUIRED_USE="^^ ( opencl cuda cpu )"

RDEPEND="opencl? (
		|| (
			virtual/opencl
			dev-util/nvidia-cuda-sdk[opencl]
			video_cards_fglrx? ( || ( x11-drivers/ati-drivers ) )
			video_cards_amdgpu? ( || ( dev-util/amdapp x11-drivers/amdgpu-pro[opencl] ) )
		)
	)
	cuda? ( dev-util/nvidia-cuda-sdk )
	"
DEPEND="${RDEPEND}
	app-arch/unrar"
PROPERTIES="interactive"
S="${WORKDIR}"

src_prepare() {
	eapply_user
}

src_unpack() {
	einfo "The author said that there is no password.  Press enter to continue."
	echo "${DISTDIR}/${A}"
	unrar x -p "${DISTDIR}/${A}"
}

src_install() {
	mkdir -p "${D}/opt/crark"
	cp -R "${WORKDIR}"/* "${D}/opt/crark"
	mkdir -p "${D}/usr/bin"
	cp "${FILESDIR}/3.4/crark" "${D}/usr/bin" #wrapper script
	cp "${FILESDIR}/3.4/crark-hp" "${D}/usr/bin" #wrapper script
}

