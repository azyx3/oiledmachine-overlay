# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
SLOT="0"

KEYWORDS="~amd64 ~ppc ~x86"
USE_DOTNET="net45"

inherit dotnet pc-file

SRC_URI="https://github.com/loresoft/msbuildtasks/archive/1.5.0.196.tar.gz -> ${P}.tar.gz"

inherit gac

RESTRICT="mirror"
S="${WORKDIR}/${PN}-${PV}"

HOMEPAGE="https://github.com/loresoft/msbuildtasks"
DESCRIPTION="The MSBuild Community Tasks Project is an open source project for MSBuild tasks."
LICENSE="BSD" # https://github.com/loresoft/msbuildtasks/blob/master/LICENSE

IUSE="+${USE_DOTNET} +debug developer doc"
REQUIRED_USE="|| ( ${USE_DOTNET} )"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5
	       =dev-dotnet/dotnetzip-semverd-1.9.3-r1[gac]"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"

src_prepare() {
	eapply "${FILESDIR}/references-2016052301.patch"
	eapply "${FILESDIR}/location.patch"

	eapply_user
}

src_compile() {
	exbuild "Source/MSBuild.Community.Tasks/MSBuild.Community.Tasks.csproj"
}

src_install() {
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	egacinstall "Source/MSBuild.Community.Tasks/obj/${DIR}/MSBuild.Community.Tasks.dll"
	einstall_pc_file "${PN}" "${PV}" "MSBuild.Community.Tasks.dll"
	insinto "/usr/$(get_libdir)/mono/${EBF}"
	doins "Source/MSBuild.Community.Tasks/MSBuild.Community.Tasks.Targets"

	if use developer ; then
		insinto "/usr/$(get_libdir)/mono/${PN}"
		doins Source/MSBuild.Community.Tasks/MSBuild.Community.Tasks.snk
		doins Source/MSBuild.Community.Tasks/obj/Release/MSBuild.Community.Tasks.dll.mdb
	fi

	dotnet_multilib_comply
}
