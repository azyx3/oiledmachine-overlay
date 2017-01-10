# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit dotnet eutils mono gac

DESCRIPTION="SDL2-CS is a C# wrapper for SDL2"
HOMEPAGE=""
PROJECT_NAME="SDL2-CS"
COMMIT="4ec65bc5a00049f7211b506ed85033f1c72c60af"
SRC_URI="https://github.com/flibitijibibo/${PROJECT_NAME}/archive/${COMMIT}.zip -> ${P}.zip"

LICENSE="zlib"
SLOT="0"
KEYWORDS="~amd64 ~x86"
USE_DOTNET="net45"
IUSE="${USE_DOTNET} debug +gac"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac"

RDEPEND=">=dev-lang/mono-4
         media-libs/libsdl2
         media-libs/sdl2-ttf
         media-libs/sdl2-mixer"
DEPEND="${RDEPEND}
	>=dev-lang/mono-4
"

S="${WORKDIR}/${PROJECT_NAME}-${COMMIT}"
SNK_FILENAME="${S}/${PN}-keypair.snk"

src_prepare() {
	sed -i -e "s|SDL2.dll|libSDL2.so|g" ./src/src/SDL2.cs
	sed -i -e "s|SDL2_image.dll|libSDL2_image.so|g" ./src/src/SDL2_image.cs
	sed -i -e "s|SDL2_mixer.dll|libSDL2_mixer.so|g" ./src/src/SDL2_mixer.cs
	sed -i -e "s|SDL2_ttf.dll|libSDL2_ttf.so|g" ./src/src/SDL2_ttf.cs

	egenkey

	eapply_user
}

src_compile() {
	mydebug="release"
	if use debug; then
		mydebug="debug"
	fi
	cd "${S}"

        einfo "Building solution"
        exbuild_strong /p:Configuration=${mydebug} ${PROJECT_NAME}.sln || die
}

src_install() {
	mydebug="Release"
	if use debug; then
		mydebug="Debug"
	fi

	esavekey

        ebegin "Installing dlls into the GAC"

	for x in ${USE_DOTNET} ; do
                FW_UPPER=${x:3:1}
                FW_LOWER=${x:4:1}
                egacinstall "${S}/bin/${mydebug}/${PROJECT_NAME}.dll"
               	insinto "/usr/$(get_libdir)/mono/${PN}"
		use developer && doins bin/${mydebug}/SDL2-CS.dll.mdb
        done

	eend

	dotnet_multilib_comply
}

