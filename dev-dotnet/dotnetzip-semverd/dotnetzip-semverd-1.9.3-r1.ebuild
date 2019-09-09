# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
SLOT="0"

KEYWORDS="~amd64 ~ppc ~x86"
USE_DOTNET="net45"

inherit dotnet pc-file

SRC_URI="https://github.com/haf/DotNetZip.Semverd/archive/v1.9.3.tar.gz -> ${P}.tar.gz"

inherit gac

RESTRICT="mirror"
S="${WORKDIR}/DotNetZip.Semverd-${PV}"

HOMEPAGE="https://github.com/haf/DotNetZip.Semverd"
DESCRIPTION="create, extract, or update zip files with C# (=DotNetZip+SemVer)"
LICENSE="MS-PL" # https://github.com/haf/DotNetZip.Semverd/blob/master/LICENSE

IUSE="net45 +gac +nupkg developer debug doc"
REQUIRED_USE="|| ( ${USE_DOTNET} ) nupkg"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"

src_prepare() {
	eapply "${FILESDIR}/version-${PV}.patch"

	cp "${DISTDIR}/mono.snk" "${S}"

	eapply_user
}

src_compile() {
	#exbuild "/p:SignAssembly=true" "/p:AssemblyOriginatorKeyFile=${S}/src/Ionic.snk" "src/Zip Reduced/Zip Reduced.csproj"
	exbuild "src/Zip Reduced/Zip Reduced.csproj"
}

src_install() {
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	egacinstall "src/Zip Reduced/bin/${DIR}/Ionic.Zip.Reduced.dll"
	einstall_pc_file "${PN}" "${PV}" "Ionic.Zip.Reduced.dll"

	dotnet_multilib_comply
}

