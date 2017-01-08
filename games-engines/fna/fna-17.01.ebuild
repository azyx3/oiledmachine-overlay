# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit eutils mono multilib-build gac

DESCRIPTION="FNA is open source XNA4"
HOMEPAGE="http://fna-xna.github.io/"
LICENSE="Ms-PL MIT GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="
        dev-dotnet/mojoshader-cs
        dev-dotnet/openal-cs
        dev-dotnet/sdl2-cs
        dev-dotnet/theoraplay-cs
        dev-dotnet/vorbisfile-cs
"
DEPEND="
	${RDEPEND}
"
USE_DOTNET="net45"
IUSE="${USE_DOTNET} debug +gac"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac"
SRC_URI="https://github.com/FNA-XNA/FNA/archive/17.01.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/FNA-${PV}"

src_unpack() {
	unpack "${A}"
}

src_prepare() {
	eapply "${FILESDIR}/fna-17.01-no-compile-libs.patch"
	eapply "${FILESDIR}/fna-17.01-refs.patch"

	eapply_user

	genkey
}

src_configure(){
	true
}

src_compile() {
	local mydebug="Release"
	if use debug; then
		mydebug="Debug"
	fi

	#inject public key into assembly
	public_key=$(sn -tp "${PN}-keypair.snk" | tail -n 7 | head -n 5 | tr -d '\n')
	echo "pk is: ${public_key}"
	cd "${S}"
	sed -i -r -e "s|\[assembly\: InternalsVisibleTo\(\"MonoGame.Framework.Content.Pipeline\"\)\]|\[assembly: InternalsVisibleTo(\"MonoGame.Framework.Content.Pipeline, PublicKey=${public_key}\")\]|" src/Properties/AssemblyInfo.cs
	sed -i -r -e "s|\[assembly\: InternalsVisibleTo\(\"MonoGame.Framework.Net\"\)\]|\[assembly: InternalsVisibleTo(\"MonoGame.Framework.Net, PublicKey=${public_key}\")\]|" src/Properties/AssemblyInfo.cs

	xbuild /p:Configuration=${mydebug} /t:Build /p:Configuration=Release FNA.sln /p:SignAssembly=true /p:AssemblyOriginatorKeyFile="${S}/${PN}-keypair.snk" || die
}

src_install() {
	local mydebug="Release"
	if use debug; then
		mydebug="Debug"
	fi

        ebegin "Installing dlls into the GAC"
	cd "${S}"

	savekey

	for x in ${USE_DOTNET} ; do
                FW_UPPER=${x:3:1}
                FW_LOWER=${x:4:1}
                egacinstall "${S}/bin/${mydebug}/FNA.dll"
        done


	eend
}

function genkey() {
	einfo "Generating Key Pair"
	cd "${S}"
	sn -k "${PN}-keypair.snk"
}

function savekey() {
	mkdir -p "${D}/usr/share/${PN}/"
	cp "${PN}-keypair.snk" "${D}/usr/share/${PN}/"
}

